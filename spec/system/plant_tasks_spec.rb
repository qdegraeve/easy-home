require "rails_helper"

# Critical journey: manual tasks of a plant (see docs/tests.md).
RSpec.describe "Plant tasks", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  it "adds a repeating and a one-off task, does them from home and plant page, cancels, edits, deletes" do
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    create(:plant, :watered, household: user.households.first, name: "Citronnier", interval_days: 7)

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"
    expect(page).to have_content("Rien à faire aujourd'hui.")
    open_plant("Citronnier")
    expect(page).to have_content("Aucune autre tâche")

    # Repeating task due today: it shows up in "À faire aujourd'hui".
    click_on "Ajouter une tâche"
    fill_in "Tâche", with: "Engrais"
    expect(page).to have_no_field("Répétition")
    choose "Tous les N jours après la dernière fois"
    fill_in "Première fois", with: Date.new(2026, 11, 16)
    fill_in "Répétition", with: "14"
    click_on "Ajouter la tâche"
    expect(page).to have_content("Tâche « Engrais » ajoutée.")
    expect(page).to have_content("Tous les 14 jours · aujourd'hui")

    # One-off task in a few days, with an input error fixed.
    click_on "Ajouter une tâche"
    fill_in "Tâche", with: "   "
    expect(page).to have_no_field("Répétition")
    fill_in "Date", with: Date.new(2026, 11, 20)
    click_on "Ajouter la tâche"
    expect(page).to have_content("Tâche doit être rempli(e)")
    fill_in "Tâche", with: "Tailler"
    click_on "Ajouter la tâche"
    expect(page).to have_content("Une fois · dans 4 j")

    go_to_tab("Aujourd'hui")
    expect(page).to have_content("À faire aujourd'hui · 1")
    click_on "Marquer comme fait : Engrais (Citronnier)"
    expect(page).to have_content("Engrais noté pour « Citronnier ».")
    expect(page).to have_content("Rien à faire aujourd'hui.")

    open_plant("Citronnier")
    expect(page).to have_content("Tous les 14 jours · dans 14 j")
    expect(page).to have_content("Fait aujourd'hui")
    open_plant_tab("Historique")
    within("section[aria-labelledby=journal]") { expect(page).to have_content("Engrais") }

    # One-off task done: it leaves the list, stays in the log; cancelled, it comes back.
    open_plant_tab("Soins")
    click_on "Marquer comme fait : Tailler (Citronnier)"
    expect(page).to have_content("Tailler noté pour « Citronnier ».")
    expect(page).to have_no_button("Marquer comme fait : Tailler (Citronnier)")
    open_plant_tab("Historique")
    within("section[aria-labelledby=journal]") { expect(page).to have_content("Tailler") }
    click_on "Annuler « Tailler » du lun 16 nov."
    within("dialog", text: "Annuler « Tailler »") { click_on "Oui, annuler" }
    expect(page).to have_content("Tailler annulé, prochaine échéance recalculée.")
    open_plant_tab("Soins")
    expect(page).to have_content("Une fois · dans 4 j")

    click_on "Modifier « Tailler »"
    fill_in "Tâche", with: "Tailler les gourmands"
    fill_in "Date", with: Date.new(2026, 11, 25)
    click_on "Enregistrer"
    expect(page).to have_content("Tâche « Tailler les gourmands » enregistrée.")
    expect(page).to have_content("Une fois · dans 9 j")

    click_on "Supprimer « Tailler les gourmands »"
    within("dialog") { click_on "Supprimer" }
    expect(page).to have_content("Tâche « Tailler les gourmands » supprimée.")
    expect(page).to have_no_link("Modifier « Tailler les gourmands »")
  end
end
