require "rails_helper"

RSpec.describe "Members", type: :request do
  let(:household) { create(:household, name: "Maison") }
  let(:manager) { create(:household_member, household:, role: :manager).user }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "passwordpassword" }
  end

  def invite(params = { role: "member", invitee_name: "Léa", email: "lea@example.com" })
    post members_path, params: { household_member: params }
  end

  def link_in(mail)
    mail.text_part.body.to_s[%r{http\S+/invitations/\S+}]
  end

  it "e-mails the invitation, lists it as pending, and sends it again with a new link" do
    sign_in(manager)

    invite
    member = household.members.invited.sole
    expect(response).to redirect_to(members_path)
    expect(flash[:notice]).to eq("Invitation envoyée à lea@example.com.")
    first = link_in(ActionMailer::Base.deliveries.last)
    expect(Invitation.find_usable(first.split("/").last).household_member).to eq(member)
    get members_path
    expect(response.parsed_body.text.squish).to include("Invitations en attente Léa lea@example.com")
    expect(response.body).not_to include(first.split("/").last)

    post member_resend_path(member)
    expect(flash[:notice]).to eq("Invitation renvoyée à lea@example.com.")
    second = link_in(ActionMailer::Base.deliveries.last)
    expect(Invitation.find_usable(first.split("/").last)).to be_nil
    expect(Invitation.find_usable(second.split("/").last).household_member).to eq(member)
  end

  it "says why it cannot invite someone already in the household, keeping the address typed" do
    create(:household_member, household:, role: :member, user: create(:user, email: "lea@example.com"))
    sign_in(manager)

    invite

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("E-mail fait déjà partie du foyer", 'value="lea@example.com"')
    expect(ActionMailer::Base.deliveries).to be_empty
  end

  it "re-renders the form on an invalid role" do
    sign_in(manager)

    invite(role: "owner", email: "lea@example.com")

    expect(response).to have_http_status(:unprocessable_content)
    expect(household.members.invited).to be_empty
  end

  it "cancels an invitation: its place and its link go" do
    sign_in(manager)
    invite
    member = household.members.invited.sole

    delete member_path(member)

    expect(response).to redirect_to(members_path)
    expect(HouseholdMember.exists?(member.id)).to be(false)
    expect(Invitation.count).to eq(0)
  end

  it "removes a member who joined: the account and the journal stay" do
    sign_in(manager)
    member = create(:household_member, household:, role: :member, user: create(:user, name: "Léa"))

    delete member_path(member)

    expect(response).to redirect_to(members_path)
    expect(flash[:notice]).to eq("Léa ne fait plus partie du foyer.")
    expect(HouseholdMember.exists?(member.id)).to be(false)
    expect(member.user.reload).to be_present
  end

  it "changes a role, but never leaves the household without a manager" do
    sign_in(manager)
    member = create(:household_member, household:, role: :member)

    own = household.members.find_by!(user: manager)
    patch member_path(own), params: { household_member: { role: "member" } }
    expect(response).to redirect_to(members_path)
    expect(flash[:alert]).to eq("Il faut au moins un gestionnaire : nommez-en un autre d'abord.")
    expect(own.reload).to be_manager

    patch member_path(member), params: { household_member: { role: "manager" } }
    expect(member.reload).to be_manager
    patch member_path(own), params: { household_member: { role: "member" } }
    expect(own.reload).to be_member
  end

  it "lets anyone leave a household, from Mes foyers, except its last manager" do
    guest = create(:household_member, household:, role: :guest)
    sign_in(guest.user)

    delete member_path(guest)
    expect(response).to redirect_to(households_path)
    expect(HouseholdMember.exists?(guest.id)).to be(false)

    sign_in(manager)
    delete member_path(household.members.find_by!(user: manager))
    expect(flash[:alert]).to eq("Il faut au moins un gestionnaire : nommez-en un autre d'abord.")
    expect(household.members.joined.manager.count).to eq(1)
  end

  it "keeps a member from changing roles or removing someone" do
    other = create(:household_member, household:, role: :member)
    sign_in(create(:household_member, household:, role: :member).user)

    patch member_path(other), params: { household_member: { role: "manager" } }
    expect(response).to have_http_status(:forbidden)
    delete member_path(other)
    expect(response).to have_http_status(:forbidden)
    expect(other.reload).to be_member
  end

  it "lets a member see the members, not invite" do
    member = create(:household_member, household:, role: :member, user: create(:user, name: "Léa")).user
    manager.update!(name: "Quentin")
    sign_in(member)

    get members_path
    expect(response.parsed_body.text.squish).to include("Léa (vous)", "Quentin Gestionnaire")
    expect(response.body).not_to include(new_member_path)

    invite
    expect(response).to have_http_status(:forbidden)
    expect(household.members.invited).to be_empty
  end

  it "keeps a guest and the visitors out" do
    get members_path
    expect(response).to redirect_to(new_session_path)

    sign_in(create(:household_member, household:, role: :guest).user)
    get members_path
    expect(response).to have_http_status(:forbidden)
    get settings_path
    expect(response.body).not_to include(members_path)
  end

  it "does not reach the places of another household" do
    other = create(:invitation).household_member
    sign_in(manager)

    delete member_path(other)

    expect(response).to have_http_status(:not_found)
    expect(HouseholdMember.exists?(other.id)).to be(true)
  end
end
