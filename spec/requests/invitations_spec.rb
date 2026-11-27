require "rails_helper"

RSpec.describe "Invitations", type: :request do
  let(:invitation) { create(:invitation) }
  let(:household) { invitation.household_member.household }
  let(:account) do
    { name: "Léa", email: "lea@example.com", password: "une phrase de passe", password_confirmation: "une phrase de passe" }
  end

  it "answers an unknown, used or expired link the same way" do
    get invitation_path("inconnu")
    unknown = response.parsed_body.at_css("main").text.squish

    Invitations::Accept.new.call(token: invitation.token, user: create(:user))
    get invitation_path(invitation.token)

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.at_css("main").text.squish).to eq(unknown)
    expect(unknown).to include("Ce lien n'est plus valable.")
  end

  it "creates the account, signs it in and opens the joined household" do
    post invitation_acceptance_path(invitation.token), params: { user: account }

    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response.body).to include("Bienvenue dans #{household.name}.")
    expect(household.members.joined.sole.user.email).to eq("lea@example.com")
  end

  it "shows the form again on an invalid account, link still usable" do
    post invitation_acceptance_path(invitation.token), params: { user: account.merge(email: "pas-un-email") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Créer votre compte")
    expect(Invitation.find_usable(invitation.token)).to eq(invitation)
  end

  it "tells someone already in the household, without using the link" do
    user = create(:household_member, household:, role: :member).user
    post session_path, params: { email: user.email, password: "passwordpassword" }

    get invitation_path(invitation.token)
    expect(response.body).to include("Vous faites déjà partie de ce foyer.")

    post invitation_acceptance_path(invitation.token)
    expect(flash[:notice]).to eq("Vous faites déjà partie de #{household.name}.")
    expect(Invitation.find_usable(invitation.token)).to eq(invitation)
  end

  it "is the only way to sign up: no account without a usable link" do
    post invitation_acceptance_path("inconnu"), params: { user: account }

    expect(response).to have_http_status(:not_found)
    expect(User.where(email: "lea@example.com")).to be_empty
  end
end
