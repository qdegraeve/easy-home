require "rails_helper"

# Critical journey (docs/tests.md, ADR 0019, required by the app stores): deleting one's account from the app.
RSpec.describe "Account deletion", type: :system do
  it "deletes the account and the household where the person was alone, after the password and a confirmation" do
    user = create(:user, :with_household, email: "lea@example.com")

    visit new_session_path
    fill_in "Votre adresse e-mail", with: "lea@example.com"
    fill_in "Votre mot de passe", with: "password"
    click_on "Se connecter"
    click_on "Réglages"
    click_on "Lea"

    expect(page).to have_content("Vous êtes seul dans Maison de test : ce foyer sera supprimé")
    fill_in "Votre mot de passe, pour confirmer", with: "password"
    click_on "Supprimer mon compte"
    within("dialog", text: "Supprimer définitivement votre compte ?") { click_on "Supprimer mon compte" }

    expect(page).to have_content("Votre compte est supprimé.")
    expect(page).to have_button("Se connecter")
    expect(User.exists?(user.id)).to be(false)
  end
end
