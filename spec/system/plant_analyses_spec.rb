require "rails_helper"

# Critical journey: AI analysis of a plant (see docs/tests.md). The analyzer is the fake one (no call to Claude).
RSpec.describe "Plant analyses", type: :system do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  # The browser runs in its own directory: it needs absolute paths.
  def picture(name)
    file_fixture(name).expand_path.to_s
  end

  it "analyses the first photo automatically, then a chosen set of photos with a note" do
    create(:user, :with_household, email: "quentin@example.com", password: "secret-password")

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"

    click_on "Ajouter une plante"
    fill_in "Nom", with: "Citronnier"
    fill_in "Arrosage", with: "3"
    attach_file "Photo", picture("plant_with_gps.jpg")
    click_on "Ajouter la plante"
    expect(page).to have_content("Analyse en cours")
    expect(page).to have_no_link("Nouvelle analyse")

    perform_enqueued_jobs
    refresh
    # Summed up on the plant page, in full on its own page.
    expect(page).to have_content("À surveiller")
    expect(page).to have_content("3 propositions à valider")
    click_on "Voir l'analyse"
    expect(page).to have_content("Citrus limon (Citronnier) · identification sûre")
    expect(page).to have_content("Pailler le pied · dans 3 j")
    click_on "← Citronnier"

    open_plant_tab("Photos")
    attach_file "Nouvelle photo", picture("plant.png") # sent once chosen
    expect(page).to have_content("Photo ajoutée.")

    @fake_plant_analyzer.answer = FakePlantAnalyzer::ANSWER.merge("health" => "ok", "actions" => [])
    open_plant_tab("Soins")
    click_on "Nouvelle analyse"
    check "Analyser la photo du mar 10 nov."
    fill_in "Une question, une remarque ? (facultatif)", with: "Est-ce que ça va mieux ?"
    click_on "Lancer l'analyse"
    expect(page).to have_content("Analyse lancée")
    expect(page).to have_content("Votre remarque : Est-ce que ça va mieux ?")

    perform_enqueued_jobs
    refresh
    expect(page).to have_content("En forme")
    expect(page).to have_css("img[alt='Photo analysée du mar 10 nov.']")
    expect(page).to have_css("img[alt='Photo analysée du lun 16 nov.']")
    expect(@fake_plant_analyzer.calls.last[:images].size).to eq(2)
    expect(@fake_plant_analyzer.calls.last[:text]).to include("Note from the owner: Est-ce que ça va mieux ?")

    # Every analysis stays in the history of the plant.
    click_on "← Citronnier"
    open_plant_tab("Historique")
    within("section[aria-labelledby=analyses]") do
      expect(page).to have_link(count: 2)
      all("a").last.click
    end
    expect(page).to have_content("Analyse de « Citronnier »")
    expect(page).to have_content("À surveiller")
  end

  it "shows a failed analysis, then restarts it with the same photos and note" do
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    plant = create(:plant, :watered, household: user.households.first, name: "Citronnier")
    older = create(:photo, plant:, taken_at: Time.zone.parse("2026-11-02 09:00"))
    create(:photo, plant:, taken_at: Time.zone.parse("2026-11-12 09:00"))
    @fake_plant_analyzer.error = "claude failed: Failed to authenticate"

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"
    open_plant("Citronnier")
    click_on "Nouvelle analyse"
    uncheck "Analyser la photo du jeu 12 nov."
    check "Analyser la photo du lun 2 nov."
    fill_in "Une question, une remarque ? (facultatif)", with: "Taches brunes ?"
    click_on "Lancer l'analyse"
    perform_enqueued_jobs
    refresh
    expect(page).to have_content("L'analyse n'a pas abouti")

    # Restarted from the plant page, where the failed analysis is summed up.
    @fake_plant_analyzer.error = nil
    click_on "← Citronnier"
    expect(page).to have_content("L'analyse n'a pas abouti")
    click_on "Relancer l'analyse"
    expect(page).to have_content("Analyse lancée")
    expect(plant.analyses.pending.sole).to have_attributes(user_note: "Taches brunes ?", photos: [ older ])

    perform_enqueued_jobs
    refresh
    expect(page).to have_content("À surveiller")
  end

  it "accepts the species, the watering interval and an action proposed by the AI" do
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    plant = create(:plant, :watered, household: user.households.first, name: "Citronnier", interval_days: 7)
    create(:photo, plant:, taken_at: Time.zone.parse("2026-11-12 09:00"))

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"
    open_plant("Citronnier")
    click_on "Nouvelle analyse"
    click_on "Lancer l'analyse"
    perform_enqueued_jobs
    refresh
    expect(page).to have_content("Citrus limon (Citronnier) · identification sûre")

    # The proposals are taken on the analysis page...
    click_on "Enregistrer l'espèce"
    expect(page).to have_content("Espèce enregistrée : Citrus limon.")
    expect(page).to have_content("Ajouté", count: 1)
    click_on "Appliquer"
    expect(page).to have_content("Arrosage réglé : tous les 4 jours.")
    expect(page).to have_content("Ajouté", count: 2)
    click_on "Ajouter « Pailler le pied » aux tâches"
    expect(page).to have_content("Tâche ajoutée : Pailler le pied.")
    expect(page).to have_content("Ajouté", count: 3)
    expect(page).to have_no_button("Ajouter « Pailler le pied » aux tâches")

    # ... and show on the plant page.
    click_on "← Citronnier"
    expect(page).to have_css("p.italic", text: "Citrus limon")
    within("section[aria-labelledby='watering']") { expect(page).to have_content("Tous les 4 jours") }
    within("section[aria-labelledby='tasks']") { expect(page).to have_content("Pailler le pied") }
    expect(page).to have_no_content("propositions à valider")
  end

  it "asks follow-up questions on an analysis, one of them with a new photo" do
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    plant = create(:plant, :watered, household: user.households.first, name: "Citronnier")
    create(:plant_analysis, :with_proposals, plant:)

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"
    open_plant("Citronnier")
    click_on "Voir l'analyse"

    find("summary", text: "Poser une question").click
    fill_in "Une question sur cette analyse ?", with: "Quel paillis utiliser ?"
    attach_file "Joindre une photo (facultatif, elle rejoint le suivi photo)", picture("plant.png")
    click_on "Envoyer la question"
    expect(page).to have_content("Question envoyée")
    expect(page).to have_content("Réponse en cours")
    expect(page).to have_css("img[alt='Photo jointe du lun 16 nov.']")
    expect(page).to have_no_button("Envoyer la question")

    perform_enqueued_jobs
    refresh
    expect(page).to have_content(FakePlantAnalyzer::FOLLOW_UP)
    expect(@fake_plant_analyzer.calls.last[:images].size).to eq(2)

    @fake_plant_analyzer.follow_up = "Une fois par semaine suffit."
    find("summary", text: "Poser une question").click
    fill_in "Une question sur cette analyse ?", with: "Et l'engrais ?"
    click_on "Envoyer la question"
    perform_enqueued_jobs
    refresh
    expect(page).to have_content("Une fois par semaine suffit.")
    expect(@fake_plant_analyzer.calls.last[:text]).to include("You: #{FakePlantAnalyzer::FOLLOW_UP}")
    click_on "← Citronnier"
    open_plant_tab("Photos")
    within("section[aria-labelledby='photos']") { expect(page).to have_css("img", count: 2) }
  end
end
