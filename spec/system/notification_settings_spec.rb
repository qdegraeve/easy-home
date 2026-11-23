require "rails_helper"

# Critical journey: notification settings (see docs/tests.md). The phone registration itself happens in the Android
# app; here the settings that drive the morning digest.
RSpec.describe "Notification settings", type: :system do
  it "turns the morning digest off, changes its time, its scope and the households it covers" do
    user = create(:user, :with_household, email: "quentin@example.com", password: "secret-password")
    create(:household_member, user:, role: :member, household: create(:household, name: "Chez Mamie"))

    visit root_path
    fill_in "Votre adresse e-mail", with: "quentin@example.com"
    fill_in "Votre mot de passe", with: "secret-password"
    click_on "Se connecter"

    click_on "Réglages"
    click_on "Notifications"
    expect(page).to have_checked_field("Recevoir le résumé du matin")
    # Saved on each change, no button to forget: a toast says it.
    expect(page).to have_no_button("Enregistrer")
    uncheck "Recevoir le résumé du matin"
    expect(page).to have_content("Enregistré.")
    select "07:30", from: "Heure du résumé"
    check "Seulement ce qui ne doit pas être raté"
    uncheck "Chez Mamie"
    expect(page).to have_no_css("form[data-autosave-pending]")

    # Everything is there when coming back.
    refresh
    expect(page).to have_unchecked_field("Recevoir le résumé du matin")
    expect(page).to have_select("Heure du résumé", selected: "07:30")
    expect(page).to have_checked_field("Seulement ce qui ne doit pas être raté")
    expect(page).to have_unchecked_field("Chez Mamie")
  end
end
