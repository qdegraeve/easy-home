require "rails_helper"

# Parcours critique : sans connexion, l'app est inutilisable (voir docs/tests.md).
RSpec.describe "Authentification", type: :system do
  let!(:user) { create(:user, email_address: "quentin@example.com", password: "secret-password") }

  it "connecte l'utilisateur puis le déconnecte" do
    visit root_path

    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"

    expect(page).to have_css("h1", text: "Easy Home")

    click_on "Se déconnecter"

    expect(page).to have_button("Se connecter")
    visit root_path
    expect(page).to have_button("Se connecter")
  end

  it "refuse un mauvais mot de passe" do
    visit new_session_path

    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "mauvais"
    click_on "Se connecter"

    expect(page).to have_content("Adresse e-mail ou mot de passe incorrect.")
    expect(page).to have_no_css("h1", text: "Easy Home")
  end
end
