require "rails_helper"

# Critical journey: notification settings (see docs/tests.md). The phone registration itself happens in the Android
# app; here the settings that drive the morning digest.
RSpec.describe "Notification settings", type: :system do
  it "turns the morning digest off, changes its time and the households it covers" do
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    create(:household_member, user:, role: :member, household: create(:household, name: "Chez Mamie"))

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"

    click_on "Notifications"
    expect(page).to have_checked_field("Recevoir le résumé du matin")
    uncheck "Recevoir le résumé du matin"
    select "07:30", from: "Heure du résumé"
    uncheck "Chez Mamie"
    click_on "Enregistrer"

    expect(page).to have_content("Réglages des notifications enregistrés.")
    expect(page).to have_unchecked_field("Recevoir le résumé du matin")
    expect(page).to have_select("Heure du résumé", selected: "07:30")
    expect(page).to have_unchecked_field("Chez Mamie")
  end
end
