require "rails_helper"

RSpec.describe "Members", type: :request do
  let(:household) { create(:household, name: "Maison") }
  let(:manager) { create(:household_member, household:, role: :manager).user }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }
  end

  def invite(params = { role: "member", invitee_name: "Léa" })
    post members_path, params: { household_member: params }
  end

  it "shows the link once, right after creating it, then offers a new one" do
    sign_in(manager)

    invite
    member = household.members.invited.sole
    expect(response).to redirect_to(member_link_path(member))
    follow_redirect!
    link = response.parsed_body.at_css("[data-invitation-link]").text
    token = link.split("/").last
    expect(Invitation.find_usable(token).household_member).to eq(member)

    get member_link_path(member)
    expect(response.parsed_body.at_css("[data-invitation-link]")).to be_nil
    expect(response.body).not_to include(token)

    post member_link_path(member)
    follow_redirect!
    new_token = response.parsed_body.at_css("[data-invitation-link]").text.split("/").last
    expect(Invitation.find_usable(token)).to be_nil
    expect(Invitation.find_usable(new_token).household_member).to eq(member)
  end

  it "re-renders the form on an invalid role" do
    sign_in(manager)

    invite(role: "guest")

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

  it "never cancels a member who joined from here" do
    sign_in(manager)
    member = create(:household_member, household:, role: :member)

    delete member_path(member)

    expect(response).to have_http_status(:forbidden)
    expect(member.reload).to be_present
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
