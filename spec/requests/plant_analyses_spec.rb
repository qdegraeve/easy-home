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

  it "queues an analysis, then shows its result on the plant page once done" do
    sign_in(user)

    params = { plant_analysis: { photo_ids: [ photo.id ], note: "Taches ?" } }
    expect { post plant_analyses_path(plant), params: }.to have_enqueued_job(AnalyzePlantJob)
    expect(response).to redirect_to(plant_path(plant))
    follow_redirect!
    expect(response.body).to include("Analyse lancée", "Analyse en cours", "Votre remarque : Taches ?")
    expect(response.body).not_to include("Nouvelle analyse")

    perform_enqueued_jobs
    get plant_path(plant)
    expect(response.body).to include("👀 À surveiller", "Citrus limon", "(Citronnier)", "identification sûre")
    expect(response.body).to include("Arrosage conseillé : tous les 4 jours", "Pailler le pied", "dans 3 j")
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

    expect(response.body).to include("Analyse de « Citronnier »", "✅ En forme", "Plante en forme.")
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

    it "forbids analysing an archived plant" do
      plant.update!(archived_at: Time.current)
      sign_in(user)

      post plant_analyses_path(plant)

      expect(response).to have_http_status(:forbidden)
    end
  end
end
