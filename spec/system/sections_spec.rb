require "rails_helper"

# Critical journey: moving between the sections of the app with the tab bar, and cancelling a completion from the
# journal (see docs/tests.md).
RSpec.describe "Sections", type: :system do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 18:30")) { example.run } }

  it "goes from Aujourd'hui to Maison, Plantes and a plant, then cancels a watering from the journal" do
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    create(
      :plant,
      :watered,
      household: user.households.sole,
      name: "Basilic",
      interval_days: 3,
      last_watered_at: Time.zone.parse("2026-11-12 08:00")
    )

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"
    expect(page).to have_css("nav[aria-label=Sections] a[aria-current=page]", text: "Aujourd'hui")
    click_on "J'ai arrosé : Basilic"
    expect(page).to have_content("Rien à faire aujourd'hui.")

    open_plant("Basilic")
    expect(page).to have_css("h1", text: "Basilic")
    expect(page).to have_css("nav[aria-label=Sections] a[aria-current=true]", text: "Maison")

    go_to_tab("Journal")
    expect(page).to have_css("h1", text: "Journal")
    # In a browser the page shows its title (the Android app shows it in its top bar instead).
    expect(page.evaluate_script("document.querySelector('h1').getBoundingClientRect().width")).to be > 1
    expect(page).to have_css("nav[aria-label=Sections] a[aria-current=page]", text: "Journal")
    expect(page).to have_content("Arrosé · par vous")
    expect(page).to have_css("h2", text: "16 novembre 2026")
    click_on "Annuler « Arrosage · Basilic » du lun 16 nov."
    within("dialog", text: "du journal ? La prochaine échéance sera recalculée.") do
      expect(page).to have_button("Garder")
      click_on "Retirer"
    end
    expect(page).to have_content("Arrosage annulé, prochaine échéance recalculée.")
    expect(page).to have_no_css("h2", text: "16 novembre 2026")

    go_to_tab("Aujourd'hui")
    expect(page).to have_button("J'ai arrosé : Basilic")
  end

  it "deletes a plant in place of its page: going back never shows it again" do
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    create(:plant, :watered, household: user.households.sole, name: "Basilic")

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"
    open_plant("Basilic")
    click_on "Supprimer"
    within("dialog") { click_on "Supprimer" }
    expect(page).to have_css("h1", text: "Plantes")
    expect(page).to have_no_link("Basilic")
    expect(page).to have_current_path(plants_path)

    page.go_back
    expect(page).to have_current_path(plants_path)
    expect(page).to have_css("h1", text: "Plantes")
  end
end
