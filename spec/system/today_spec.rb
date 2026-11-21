require "rails_helper"

# Critical journey: the waterings of the day on a single line, done in one tap, undone, then detailed by location
# (see docs/tests.md).
RSpec.describe "Today", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 18:30")) { example.run } }

  it "waters all the plants of the day in one tap, undoes it, then waters only the checked ones" do
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    household = user.households.sole
    terrace = create(:location, household:, name: "Terrasse")
    watered = Time.zone.parse("2026-11-12 08:00")
    create(:plant, :watered, household:, name: "Basilic", location: terrace, interval_days: 3, last_watered_at: watered)
    create(:plant, :watered, household:, name: "Menthe", location: terrace, interval_days: 3, last_watered_at: watered)
    create(:plant, :watered, household:, name: "Aloe", interval_days: 3, last_watered_at: watered)
    create(:plant, :watered, household:, name: "Cactus", interval_days: 3,
                             last_watered_at: Time.zone.parse("2026-11-15 08:00"))

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"

    # One line for the three waterings due, where they are; the one of the coming days folded under "Bientôt".
    expect(page).to have_content("À faire aujourd'hui · 3")
    expect(page).to have_content("Terrasse 2 · sans emplacement 1")
    expect(page).to have_no_button("Arrosée : Basilic")
    expect(page).to have_content("Bientôt · 1")
    find("summary", text: "Bientôt").click
    expect(page).to have_content("Arroser Cactus")

    click_on "Tout arroser : 3 plantes"
    expect(page).to have_content("3 arrosages notés.")
    expect(page).to have_content("Rien à faire aujourd'hui.")

    # A wrong tap is repaired on the spot.
    within("[data-controller=toast]") { click_on "Annuler" }
    expect(page).to have_content("3 annulés, prochaines échéances recalculées.")
    expect(page).to have_content("À faire aujourd'hui · 3")

    # The detail: everything checked, uncheck the one not watered.
    click_on "Arroser"
    expect(page).to have_css("h1", text: "Arroser 3 plantes")
    within("section", text: "Terrasse") { uncheck "Menthe" }
    click_on "Valider les arrosages cochés"

    expect(page).to have_content("2 arrosages notés.")
    expect(page).to have_content("À faire aujourd'hui · 1")
    expect(page).to have_button("Arrosée : Menthe")
  end
end
