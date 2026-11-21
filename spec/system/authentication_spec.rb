require "rails_helper"

# Critical journey: without signing in, the app is unusable (see docs/tests.md).
RSpec.describe "Authentication", type: :system do
  let!(:user) { create(:user, :with_household, email: "quentin@example.com", password: "secret-password") }

  it "signs the user in then out" do
    visit root_path

    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"

    expect(page).to have_css("h1", text: "Mes plantes")

    click_on "Se déconnecter"
    within("dialog", text: "Se déconnecter ?") { click_on "Se déconnecter" }

    expect(page).to have_button("Se connecter")
    visit root_path
    expect(page).to have_button("Se connecter")
  end

  it "rejects a wrong password" do
    visit new_session_path

    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "mauvais"
    click_on "Se connecter"

    expect(page).to have_content("Adresse e-mail ou mot de passe incorrect.")
    expect(page).to have_no_css("h1", text: "Mes plantes")

    # The error stays until closed, and screen readers hear it through the live region.
    expect(page).to have_css("#announcer[aria-live=assertive]", text: "Adresse e-mail ou mot de passe incorrect.",
                                                                visible: :all)
    click_on "Fermer le message"
    expect(page).to have_no_content("Adresse e-mail ou mot de passe incorrect.")
  end
end
