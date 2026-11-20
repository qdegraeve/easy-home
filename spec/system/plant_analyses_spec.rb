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

    click_on "+ Ajouter une plante"
    fill_in "Nom", with: "Citronnier"
    fill_in "Arrosage", with: "3"
    attach_file "Photo", picture("plant_with_gps.jpg")
    click_on "Ajouter la plante"
    expect(page).to have_content("Analyse en cours")
    expect(page).to have_no_link("Nouvelle analyse")

    perform_enqueued_jobs
    refresh
    expect(page).to have_content("👀 À surveiller")
    expect(page).to have_content("Citrus limon (Citronnier) · identification sûre")
    expect(page).to have_content("Pailler le pied · dans 3 j")

    attach_file "Nouvelle photo", picture("plant.png")
    click_on "Ajouter la photo"
    expect(page).to have_content("Photo ajoutée.")

    @fake_plant_analyzer.answer = FakePlantAnalyzer::ANSWER.merge("health" => "ok", "actions" => [])
    click_on "Nouvelle analyse"
    check "Analyser la photo du mar 10 nov."
    fill_in "Une question, une remarque ? (facultatif)", with: "Est-ce que ça va mieux ?"
    click_on "Lancer l'analyse"
    expect(page).to have_content("Analyse lancée")
    expect(page).to have_content("Votre remarque : Est-ce que ça va mieux ?")

    perform_enqueued_jobs
    refresh
    expect(page).to have_content("✅ En forme")
    expect(page).to have_css("img[alt='Photo analysée du mar 10 nov.']")
    expect(page).to have_css("img[alt='Photo analysée du lun 16 nov.']")
    expect(@fake_plant_analyzer.calls.last[:images].size).to eq(2)
    expect(@fake_plant_analyzer.calls.last[:text]).to include("Note from the owner: Est-ce que ça va mieux ?")

    find("summary", text: "Analyses précédentes · 1").click
    within("details") { click_on "lun 16 nov." }
    expect(page).to have_content("Analyse de « Citronnier »")
    expect(page).to have_content("👀 À surveiller")
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
    click_on "Citronnier"
    click_on "Nouvelle analyse"
    uncheck "Analyser la photo du jeu 12 nov."
    check "Analyser la photo du lun 2 nov."
    fill_in "Une question, une remarque ? (facultatif)", with: "Taches brunes ?"
    click_on "Lancer l'analyse"
    perform_enqueued_jobs
    refresh
    expect(page).to have_content("L'analyse n'a pas abouti")

    @fake_plant_analyzer.error = nil
    click_on "Relancer l'analyse"
    expect(page).to have_content("Analyse lancée")
    expect(plant.analyses.pending.sole).to have_attributes(user_note: "Taches brunes ?", photos: [ older ])

    perform_enqueued_jobs
    refresh
    expect(page).to have_content("👀 À surveiller")
  end

  it "accepts the species, the watering interval and an action proposed by the AI" do
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    plant = create(:plant, :watered, household: user.households.first, name: "Citronnier", interval_days: 7)
    create(:photo, plant:, taken_at: Time.zone.parse("2026-11-12 09:00"))

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"
    click_on "Citronnier"
    click_on "Nouvelle analyse"
    click_on "Lancer l'analyse"
    perform_enqueued_jobs
    refresh
    expect(page).to have_content("Citrus limon (Citronnier) · identification sûre")

    click_on "Enregistrer l'espèce"
    expect(page).to have_content("Espèce enregistrée : Citrus limon.")
    expect(page).to have_css("p.italic", text: "Citrus limon")
    expect(page).to have_content("✓ Sur la fiche")

    within("section[aria-labelledby='watering']") { expect(page).to have_content("Tous les 7 jours") }
    click_on "Appliquer"
    expect(page).to have_content("Arrosage réglé : tous les 4 jours.")
    within("section[aria-labelledby='watering']") { expect(page).to have_content("Tous les 4 jours") }
    expect(page).to have_content("✓ En place")

    click_on "Ajouter « Pailler le pied » aux tâches"
    expect(page).to have_content("Tâche ajoutée : Pailler le pied.")
    within("section[aria-labelledby='tasks']") { expect(page).to have_content("Pailler le pied") }
    expect(page).to have_content("✓ Dans les tâches")
    expect(page).to have_no_button("Ajouter « Pailler le pied » aux tâches")
  end
end
