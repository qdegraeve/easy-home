require "rails_helper"

# Critical journey: in the Android app (Hotwire Native user agent), the web header is hidden; the settings, sign out
# included, are reached from the home page (see docs/tests.md).
RSpec.describe "In the Android app", type: :system do
  before do
    page.driver.add_headers("User-Agent" => "Mozilla/5.0 (Linux; Android 17) Hotwire Native Android")
  end

  it "reaches the notification settings then signs out through the settings, without the web header" do
    create(:user, :with_household, email: "quentin@example.com", password: "secret-password")

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"

    expect(page).to have_css("h1", text: "Aujourd'hui")
    expect(page).to have_no_css("header")

    click_on "Réglages"
    click_on "Notifications"
    expect(page).to have_css("h1", text: "Notifications")
    expect(page).to have_no_link("← Accueil")

    visit settings_path
    click_on "Se déconnecter"
    within("dialog", text: "Se déconnecter ?") { click_on "Se déconnecter" }

    expect(page).to have_button("Se connecter")
  end
end
