require "rails_helper"

RSpec.describe "Invitations", type: :request do
  let(:invitation) { create(:invitation, email: "lea@example.com") }
  let(:household) { invitation.household_member.household }
  let(:account) { { name: "Léa", password: "une phrase de passe", password_confirmation: "une phrase de passe" } }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "passwordpassword" }
  end

  it "answers an unknown, used or expired link the same way" do
    get invitation_path("inconnu")
    unknown = response.parsed_body.at_css("main").text.squish

    Invitations::Accept.new.call(token: invitation.token, account:)
    get invitation_path(invitation.token)

    expect(response).to have_http_status(:not_found)
    expect(response.parsed_body.at_css("main").text.squish).to eq(unknown)
    expect(unknown).to include("Ce lien n'est plus valable.")
  end

  it "shows the invited address, not to be changed, then creates its account, signed in, in the household" do
    get invitation_path(invitation.token)
    expect(response.parsed_body.text.squish).to include("E-mail lea@example.com")
    expect(response.parsed_body.at_css("input[name='user[email]']")).to be_nil

    post invitation_acceptance_path(invitation.token), params: { user: account.merge(email: "autre@example.com") }

    expect(response).to redirect_to(root_path)
    follow_redirect!
    expect(response.body).to include("Bienvenue dans #{household.name}.")
    expect(household.members.joined.sole.user.email).to eq("lea@example.com")
  end

  it "shows the form again on a weak password, link still usable" do
    post invitation_acceptance_path(invitation.token),
      params: { user: account.merge(password: "court", password_confirmation: "court") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Créer votre compte", "15 caractères")
    expect(Invitation.find_usable(invitation.token)).to eq(invitation)
  end

  it "keeps another account out: the invitation is for its address only" do
    sign_in(create(:user, :with_household, email: "autre@example.com"))

    get invitation_path(invitation.token)
    expect(response.body).to include("Cette invitation est pour lea@example.com.")

    post invitation_acceptance_path(invitation.token)
    expect(flash[:alert]).to eq("Cette invitation est pour lea@example.com, pas pour ce compte.")
    expect(Invitation.find_usable(invitation.token)).to eq(invitation)
  end

  it "tells someone already in the household, without using the link" do
    sign_in(create(:household_member, household:, role: :member, user: create(:user, email: "lea@example.com")).user)

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
