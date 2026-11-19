require "rails_helper"

# Parcours critique : sans foyer, l'app est inutilisable (voir docs/tests.md).
RSpec.describe "Foyers", type: :system do
  it "crée un premier foyer à la première connexion, puis en ajoute un second et change de foyer" do
    create(:user, email: "quentin@example.com", password: "secret-password")

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"

    expect(page).to have_css("h1", text: "Créer un foyer")
    fill_in "Nom du foyer", with: "Maison"
    click_on "Créer le foyer"

    expect(page).to have_content("Foyer « Maison » créé.")
    expect(page).to have_css("h1", text: "Mes plantes")

    click_on "Maison"
    click_on "+ Nouveau foyer"
    fill_in "Nom du foyer", with: "Case des Hauts"
    click_on "Créer le foyer"
    expect(page).to have_link("Case des Hauts")

    click_on "Case des Hauts"
    click_on "Choisir"

    expect(page).to have_link("Maison")
    expect(page).to have_css("h1", text: "Mes plantes")
  end
end
