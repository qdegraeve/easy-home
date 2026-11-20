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
end
