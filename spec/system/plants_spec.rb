require "rails_helper"

# Critical journeys: adding a plant, watering, correction, archiving (see docs/tests.md).
RSpec.describe "Plants", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  it "adds a plant, waters it, fixes the log, changes the interval, archives then restores it" do
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    create(:location, household: user.households.first, name: "Terrasse", exposure: :partial_shade)

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"
    click_on "Ajouter une plante"

    # Invalid input (the browser blocks the others): the server error shows and values are kept.
    fill_in "Nom", with: "   "
    select "Terrasse", from: "Emplacement"
    fill_in "Arrosage", with: "2"
    find("summary", text: "Plus de détails").click
    fill_in "Dernier arrosage", with: Date.new(2026, 11, 14)
    click_on "Ajouter la plante"
    expect(page).to have_content("Nom doit être rempli(e)")
    expect(page).to have_field("Arrosage", with: "2")

    fill_in "Nom", with: "Basilic"
    click_on "Ajouter la plante"
    expect(page).to have_content("Plante « Basilic » ajoutée.")
    expect(page).to have_content("Tous les 2 jours")
    expect(page).to have_content("Prochain arrosage : aujourd'hui")
    expect(page).to have_content("Dernier arrosage : sam 14 nov.")

    # Watering from the home page, once a day.
    go_to_tab("Aujourd'hui")
    expect(page).to have_content("À faire aujourd'hui · 1")
    click_on "Arrosée : Basilic"
    expect(page).to have_content("Arrosage noté pour « Basilic ».")
    expect(page).to have_content("Rien à faire aujourd'hui.")

    # Back to the home page: the message of the watering is not shown again from Turbo's cache.
    go_to_tab("Maison")
    page.go_back
    expect(page).to have_content("Rien à faire aujourd'hui.")
    expect(page).to have_no_content("Arrosage noté pour « Basilic ».")

    open_plant("Basilic")
    expect(page).to have_content("Prochain arrosage : dans 2 j")
    expect(page).to have_content("Arrosée aujourd'hui")
    expect(page).to have_no_button("Arrosée : Basilic")

    # Correction: today's watering was a mistake.
    open_plant_tab("Historique")
    click_on "Annuler l'arrosage du lun 16 nov."
    within("dialog", text: "Le prochain arrosage sera recalculé.") { click_on "Oui, annuler" }
    expect(page).to have_content("Arrosage annulé, prochaine échéance recalculée.")
    expect(page).to have_content("Prochain arrosage : aujourd'hui")
    expect(page).to have_content("Dernier arrosage : sam 14 nov.")
    expect(page).to have_button("Arrosée : Basilic")

    # New interval: the occurrence is rescheduled from the last watering (Nov 14 + 5 days).
    click_on "Modifier"
    fill_in "Arrosage", with: "5"
    click_on "Enregistrer"
    expect(page).to have_content("Plante enregistrée.")
    expect(page).to have_content("Tous les 5 jours")
    expect(page).to have_content("Prochain arrosage : dans 3 j")

    # Archiving: no more reminders, the log remains.
    click_on "Archiver"
    within("dialog") { click_on "Revenir" }
    expect(page).to have_no_css("dialog[open]")
    expect(page).to have_no_content("Plante « Basilic » archivée.")
    click_on "Archiver"
    expect(page).to have_css("dialog[open] button[data-tone='']", text: "Archiver")
    within("dialog", text: "Les rappels s'arrêtent") { click_on "Archiver" }
    expect(page).to have_content("Plante « Basilic » archivée.")
    expect(page).to have_content("plus de rappel")
    expect(page).to have_no_button("Arrosée : Basilic")
    click_on "← Plantes"
    expect(page).to have_content("Plantes archivées · 1")

    # Restore a few days later: watering resumes, late.
    travel 7.days
    find("summary", text: "Plantes archivées · 1").click
    click_on "Basilic"
    click_on "Restaurer"
    expect(page).to have_content("Plante « Basilic » restaurée.")
    expect(page).to have_content("Prochain arrosage : prévu il y a 4 j")
    expect(page).to have_button("Arrosée : Basilic")
  end
end
