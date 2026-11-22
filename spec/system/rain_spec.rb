require "rails_helper"

# Critical journey: rain counts as a watering (see docs/tests.md and ADR 0015). The owner says that a place gets the
# rain; that evening, heavy rain waters its plants; the next morning, "Aujourd'hui" says so and the journal shows it,
# undoable like a manual watering.
RSpec.describe "Rain", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  it "marks a place as getting the rain, then sees its plants watered by the rain, and undoes it" do
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    household = user.households.sole
    household.update!(latitude: -20.9, longitude: 55.45)
    garden = create(:location, household:, name: "Jardin")
    create(:plant, :watered, household:, name: "Citronnier", location: garden, interval_days: 3,
                             last_watered_at: Time.zone.parse("2026-11-13 08:00"))

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"
    expect(page).to have_content("Citronnier")

    go_to_tab("Maison")
    click_on "Adresse et emplacements"
    click_on "Modifier l'emplacement « Jardin »"
    check "Reçoit la pluie"
    click_on "Enregistrer"
    expect(page).to have_content("Emplacement « Jardin » modifié.")
    expect(page).to have_content("reçoit la pluie")

    # 14 mm fell that day: the evening job waters the lemon tree.
    travel_to(Time.zone.parse("2026-11-16 22:00"))
    Weather.rain.result = 14.2
    RecordRainJob.perform_now

    travel_to(Time.zone.parse("2026-11-17 07:30"))
    go_to_tab("Aujourd'hui")
    expect(page).to have_content("Pluie hier : elle compte comme un arrosage pour Citronnier.")
    expect(page).to have_content("Rien à faire aujourd'hui.")

    click_on "Voir le journal"
    expect(page).to have_content("Arrosage · Citronnier")
    expect(page).to have_content("par la pluie")
    click_on "Annuler « Arrosage · Citronnier » du lun 16 nov."
    within("dialog", text: "Annuler « Arrosage · Citronnier »") { click_on "Oui, annuler" }
    expect(page).to have_no_content("par la pluie")

    go_to_tab("Aujourd'hui")
    expect(page).to have_no_content("Pluie hier")
    expect(page).to have_css("section[aria-labelledby=due-today]", text: "Citronnier")
  end
end
