require "rails_helper"

# Critical journeys (docs/tests.md, ADR 0019): a manager invites someone by a link, who joins with or without an
# account, and the household is shared.
RSpec.describe "Invitations", type: :system do
  let(:household) { create(:household, name: "Maison") }
  let!(:manager) do
    create(:household_member, household:, role: :manager,
                              user: create(:user, name: "Quentin", email: "quentin@example.com")).user
  end

  def sign_in(email, password = "passwordpassword")
    visit new_session_path
    fill_in "Votre adresse e-mail", with: email
    fill_in "Votre mot de passe", with: password
    click_on "Se connecter"
    expect(page).to have_css("h1", text: "Aujourd'hui")
  end

  def sign_out
    click_on "Réglages"
    click_on "Se déconnecter"
    within("dialog", text: "Se déconnecter ?") { click_on "Se déconnecter" }
    expect(page).to have_button("Se connecter")
  end

  it "invites someone who creates their account from the link and joins the household" do
    create(:plant, household:, name: "Ficus")
    sign_in("quentin@example.com")

    click_on "Réglages"
    click_on "Membres du foyer"
    click_on "Inviter quelqu'un"
    fill_in "Pour qui ?", with: "Léa"
    choose "Membre"
    click_on "Créer le lien"

    link = find("[data-invitation-link]").text
    expect(page).to have_button("Copier")
    click_on "← Membres"
    expect(page).to have_content("Léa")
    expect(page).to have_content("Membre, lien valable jusqu'au")
    sign_out

    visit link
    expect(page).to have_css("h1", text: "Rejoindre Maison")
    expect(page).to have_content("Quentin vous invite comme membre.")
    fill_in "Prénom", with: "Léa"
    fill_in "E-mail", with: "lea@example.com"
    fill_in "Mot de passe", with: "passwordpassword"
    fill_in "Confirmation du mot de passe", with: "passwordpassword"
    click_on "Créer mon compte et rejoindre Maison"

    expect(page).to have_content("Bienvenue dans Maison.")
    go_to_tab("Maison")
    click_on "Plantes"
    expect(page).to have_link("Ficus")

    click_on "Réglages"
    click_on "Membres du foyer"
    expect(page).to have_content("Léa (vous)")
    expect(page).to have_content("Quentin")
    expect(page).to have_no_content("Invitations en attente")
    expect(page).to have_no_link("Inviter quelqu'un")

    visit link
    expect(page).to have_css("h1", text: "Lien expiré")
  end

  it "lets someone with an account sign in from the link, then join" do
    create(:user, :with_household, email: "lea@example.com")
    invitation = create(:invitation, household_member: build(:household_member, household:, user: nil, role: :member))

    visit invitation_path(invitation.token)
    click_on "Se connecter"
    fill_in "Votre adresse e-mail", with: "lea@example.com"
    fill_in "Votre mot de passe", with: "passwordpassword"
    click_on "Se connecter"

    expect(page).to have_css("h1", text: "Rejoindre Maison")
    click_on "Rejoindre Maison"
    expect(page).to have_content("Bienvenue dans Maison.")
    expect(household.members.joined.map { _1.user.email }).to contain_exactly("quentin@example.com", "lea@example.com")
  end
end
