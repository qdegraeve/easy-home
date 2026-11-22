require "rails_helper"

# Critical journey: importance and tolerance of the tasks (see docs/tests.md). A task that must not be missed comes
# first, in red, and is missed the day after; a late watering stays to do during its tolerance, then is missed and
# still to do. Both show in the journal. A task of the day can also be postponed to tomorrow.
RSpec.describe "Task importance", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  it "puts a task that must not be missed first in red, then shows it and a late watering missed" do
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    create(:plant, :watered, household: user.households.first, name: "Citronnier", interval_days: 7,
                             last_watered_at: Time.zone.parse("2026-11-09 08:00"))

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"
    open_plant("Citronnier")
    click_on "Ajouter une tâche"
    fill_in "Tâche", with: "Traitement"
    fill_in "Date", with: Date.new(2026, 11, 16)
    check "À ne pas rater"
    click_on "Ajouter la tâche"
    expect(page).to have_content("Tâche « Traitement » ajoutée.")

    go_to_tab("Aujourd'hui")
    within("section[aria-labelledby=due-today]") do
      expect(page.all("li").first).to have_text("Traitement")
      expect(page).to have_css(".text-alert", text: "aujourd'hui")
    end

    # Three days later, nothing done: the treatment is missed, the watering (every 7 days, 2 days of tolerance)
    # was due on 16 November and is missed on the 19th, then still to do, showing how late it is.
    travel_to(Time.zone.parse("2026-11-19 01:05"))
    Tasks::MarkMissed.new.call
    visit root_path
    expect(page).to have_no_content("Traitement")
    expect(page).to have_content("Arrosage · prévu il y a 3 j")

    go_to_tab("Journal")
    expect(page).to have_content("Traitement · Citronnier")
    expect(page).to have_content("Non fait, prévu le lun 16 nov.", count: 2) # the treatment and the watering

    open_plant("Citronnier")
    open_plant_tab("Historique")
    expect(page).to have_content("Arrosage manqué")
    expect(page).to have_content("Traitement : manquée")
  end

  it "postpones a task of the day to tomorrow, with a discreet trace in the journal" do
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    create(:plant, :watered, household: user.households.first, name: "Citronnier", interval_days: 7,
                             last_watered_at: Time.zone.parse("2026-11-09 08:00"))

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"
    expect(page).to have_content("À faire aujourd'hui · 1")

    # Tapped by mistake: undone from the toast.
    click_on "Reporter à demain : Arrosage (Citronnier)"
    expect(page).to have_content("Reporté à demain : Arrosage (Citronnier).")
    expect(page).to have_content("Rien à faire aujourd'hui.")
    within("#toasts") { click_on "Annuler" }
    expect(page).to have_content("Décalage annulé.")
    expect(page).to have_content("À faire aujourd'hui · 1")

    click_on "Reporter à demain : Arrosage (Citronnier)"
    expect(page).to have_content("Rien à faire aujourd'hui.")

    go_to_tab("Journal")
    expect(page).to have_content("Arrosage · Citronnier")
    expect(page).to have_content("Échéance reportée · par vous", count: 1)
    open_plant("Citronnier")
    open_plant_tab("Historique")
    expect(page).to have_content("Arrosage : échéance reportée")

    travel_to(Time.zone.parse("2026-11-17 09:00"))
    go_to_tab("Aujourd'hui")
    expect(page).to have_content("À faire aujourd'hui · 1")
    expect(page).to have_button("J'ai arrosé : Citronnier")
  end
end
