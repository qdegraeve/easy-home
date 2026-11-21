require "rails_helper"

# Critical journey: without a household, the app is unusable (see docs/tests.md).
RSpec.describe "Households", type: :system do
  it "creates a first household on first sign in, then adds a second one and switches" do
    create(:user, email: "quentin@example.com", password: "secret-password")

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"

    expect(page).to have_css("h1", text: "Créer un foyer")
    fill_in "Nom du foyer", with: "Maison"
    click_on "Créer le foyer"

    expect(page).to have_content("Foyer « Maison » créé.")
    expect(page).to have_css("h1", text: "Aujourd'hui")

    within("main") { click_on "Maison" }
    click_on "+ Nouveau foyer"
    fill_in "Nom du foyer", with: "Case des Hauts"
    click_on "Créer le foyer"
    expect(page).to have_link("Case des Hauts")

    click_on "Case des Hauts"
    click_on "Choisir"

    within("main") { expect(page).to have_link("Maison") }
    expect(page).to have_css("h1", text: "Aujourd'hui")
  end
end
