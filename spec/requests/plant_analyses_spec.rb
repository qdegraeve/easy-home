require "rails_helper"

RSpec.describe "Plant analyses", type: :request do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household) }
  let(:user) { create(:household_member, household:, role: :member).user }
  let(:plant) { create(:plant, :watered, household:, name: "Citronnier") }
  let!(:photo) { create(:photo, plant:, taken_at: Time.zone.parse("2026-11-12 09:00")) }

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }
  end

  it "shows the form with the latest photo preselected" do
    create(:photo, plant:, taken_at: Time.zone.parse("2026-11-02 09:00"))
    sign_in(user)

    get new_plant_analysis_path(plant)

    expect(response.body).to include("Nouvelle analyse", "Analyser la photo du jeu 12 nov.")
    expect(response.body).to include("Analyser la photo du lun 2 nov.")
    expect(response.body).to match(/value="#{photo.id}"[^>]*checked/)
  end

  it "queues an analysis on its own page, then shows its result there and its summary on the plant page" do
    sign_in(user)

    params = { plant_analysis: { photo_ids: [ photo.id ], note: "Taches ?" } }
    expect { post plant_analyses_path(plant), params: }.to have_enqueued_job(AnalyzePlantJob)
    analysis = plant.analyses.sole
    expect(response).to redirect_to(plant_analysis_path(plant, analysis))
    follow_redirect!
    expect(response.body).to include("Analyse lancée", "Analyse en cours", "Votre remarque : Taches ?")
    get plant_path(plant)
    expect(response.body).to include("Analyse en cours")
    expect(response.body).not_to include("Nouvelle analyse")

    perform_enqueued_jobs
    get plant_analysis_path(plant, analysis)
    expect(response.body).to include("À surveiller", "Citrus limon", "(Citronnier)", "identification sûre")
    expect(response.body).to include("Arrosage conseillé : tous les 4 jours", "Pailler le pied", "dans 3 j")
    get plant_path(plant)
    expect(response.parsed_body.text.squish).to include("À surveiller", "3 propositions à valider", "Voir l'analyse")
  end

  it "shows a failed analysis with a restart button that reuses its photos and note" do
    @fake_plant_analyzer.error = "claude failed"
    sign_in(user)
    post plant_analyses_path(plant), params: { plant_analysis: { photo_ids: [ photo.id ], note: "Taches ?" } }
    perform_enqueued_jobs

    get plant_path(plant)
    expect(response.body).to include("L&#39;analyse n&#39;a pas abouti", "Relancer l&#39;analyse")

    post plant_analyses_path(plant), params: { plant_analysis: { photo_ids: [ photo.id ], note: "Taches ?" } }
    expect(plant.analyses.recent_first.first).to have_attributes(status: "pending", user_note: "Taches ?")
  end

  it "hides the restart button of a failed analysis whose photos were deleted" do
    analysis = create(:plant_analysis, plant:, photos: [ photo ])
    analysis.update!(status: :failed, error: "x")
    photo.destroy!
    sign_in(user)

    get plant_path(plant)

    expect(response.body).to include("L&#39;analyse n&#39;a pas abouti")
    expect(response.body).not_to include("Relancer l&#39;analyse")
  end

  it "answers 400 to a malformed request" do
    sign_in(user)

    post plant_analyses_path(plant), params: { plant_analysis: "foo" }

    expect(response).to have_http_status(:bad_request)
    expect(plant.analyses).to be_empty
  end

  it "escapes the AI text: no link or image can come from the answer" do
    sign_in(user)
    @fake_plant_analyzer.answer = FakePlantAnalyzer::ANSWER.merge(
      "observations" => %(Voir <a href="https://evil.example/x">ici</a> <img src="https://evil.example/p.gif">)
    )
    post plant_analyses_path(plant)
    perform_enqueued_jobs

    get plant_path(plant)

    expect(response.body).not_to include("evil.example/x\">", "<img src=\"https://evil")
    expect(response.body).to include("&lt;a href=")
  end

  it "re-renders the form when more than 5 photos are chosen" do
    ids = create_list(:photo, 5, plant:).map(&:id) + [ photo.id ]
    sign_in(user)

    post plant_analyses_path(plant), params: { plant_analysis: { photo_ids: ids } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Photos à analyser : 5 au maximum")
  end

  it "refuses a second analysis while one is pending" do
    sign_in(user)
    post plant_analyses_path(plant)

    post plant_analyses_path(plant)

    expect(flash[:alert]).to eq("Une analyse est déjà en cours pour cette plante.")
    expect(plant.analyses.count).to eq(1)
  end

  it "shows a previous analysis on its own page" do
    analysis = create(:plant_analysis, :done, plant:, photos: [ photo ])
    sign_in(user)

    get plant_analysis_path(plant, analysis)

    expect(response.body).to include("Analyse de « Citronnier »", "En forme", "Plante en forme.")
  end

  describe "accepting the proposals" do
    let(:analysis) { create(:plant_analysis, :with_proposals, plant:, photos: [ photo ]) }

    before { sign_in(user) }

    it "sets the species, the watering interval and adds an action as a task, then shows them as accepted" do
      post accept_species_plant_analysis_path(plant, analysis)
      expect(flash[:notice]).to eq("Espèce enregistrée : Citrus limon.")
      post accept_watering_plant_analysis_path(plant, analysis)
      expect(flash[:notice]).to eq("Arrosage réglé : tous les 4 jours.")
      post accept_action_plant_analysis_path(plant, analysis, index: 0)
      expect(flash[:notice]).to eq("Tâche ajoutée : Pailler le pied.")
      expect(response).to redirect_to(plant_analysis_path(plant, analysis))

      get plant_analysis_path(plant, analysis)
      expect(response.body).to include("Sur la fiche", "En place", "Dans les tâches")
      expect(response.body).not_to include("Enregistrer l&#39;espèce", "Ajouter aux tâches")
    end

    it "goes back to the analysis page when accepted from there" do
      post accept_species_plant_analysis_path(plant, analysis),
        headers: { "Referer" => plant_analysis_url(plant, analysis) }

      expect(response).to redirect_to(plant_analysis_url(plant, analysis))
    end

    it "refuses to add the same action twice" do
      post accept_action_plant_analysis_path(plant, analysis, index: 0)

      post accept_action_plant_analysis_path(plant, analysis, index: 0)

      expect(flash[:alert]).to eq("Cette action est déjà dans les tâches.")
      expect(plant.tasks.where(title: "Pailler le pied").count).to eq(1)
    end

    it "refuses an action that does not exist" do
      post accept_action_plant_analysis_path(plant, analysis, index: 3)

      expect(flash[:alert]).to eq("Cette proposition ne peut pas être appliquée.")
    end

    it "forbids accepting the proposals of an analysis that is not done" do
      analysis.update!(status: :failed)

      post accept_species_plant_analysis_path(plant, analysis)

      expect(response).to have_http_status(:forbidden)
      expect(plant.reload.species).to be_nil
    end

    it "forbids accepting the proposals of an archived plant" do
      plant.update!(archived_at: Time.current)

      post accept_watering_plant_analysis_path(plant, analysis)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "access denied" do
    {
      "a guest of the household" => -> { create(:household_member, household:, role: :guest).user },
      "a user of another household" => -> { create(:user, :with_household) }
    }.each do |intruder_label, intruder|
      it "answers 404 to #{intruder_label} on the form, the creation and an analysis page" do
        analysis = create(:plant_analysis, :done, plant:, photos: [ photo ])
        sign_in(instance_exec(&intruder))

        get new_plant_analysis_path(plant)
        expect(response).to have_http_status(:not_found)
        post plant_analyses_path(plant)
        expect(response).to have_http_status(:not_found)
        get plant_analysis_path(plant, analysis)
        expect(response).to have_http_status(:not_found)
        expect(plant.analyses.count).to eq(1)
      end
    end

    it "answers 404 to a guest accepting a proposal" do
      analysis = create(:plant_analysis, :with_proposals, plant:, photos: [ photo ])
      sign_in(create(:household_member, household:, role: :guest).user)

      post accept_species_plant_analysis_path(plant, analysis)
      expect(response).to have_http_status(:not_found)
      post accept_action_plant_analysis_path(plant, analysis, index: 0)
      expect(response).to have_http_status(:not_found)
      expect(plant.reload.species).to be_nil
      expect(plant.tasks.count).to eq(1)
    end

    it "forbids analysing an archived plant" do
      plant.update!(archived_at: Time.current)
      sign_in(user)

      post plant_analyses_path(plant)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
