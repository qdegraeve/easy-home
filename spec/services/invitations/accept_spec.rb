require "rails_helper"

RSpec.describe Invitations::Accept do
  let(:invitation) { create(:invitation) }
  let(:household) { invitation.household_member.household }
  let(:account) do
    { name: "Léa", email: "lea@example.com", password: "secret-123", password_confirmation: "secret-123" }
  end

  it "gives the place to the signed-in user and uses the link up" do
    user = create(:user)

    member = described_class.new.call(token: invitation.token, user:).value!

    expect(member).to have_attributes(user:, household:, role: "member")
    expect(invitation.reload.accepted_at).to be_present
    expect(Invitation.find_usable(invitation.token)).to be_nil
  end

  it "creates the account from the link, then gives it the place" do
    member = described_class.new.call(token: invitation.token, account:).value!

    expect(member.user).to have_attributes(name: "Léa", email: "lea@example.com")
    expect(member.user.authenticate("secret-123")).to be_truthy
  end

  it "creates nothing from an invalid account and keeps the link" do
    result = described_class.new.call(token: invitation.token, account: account.merge(password_confirmation: "autre"))

    expect(result.failure.first).to eq(:invalid_account)
    expect(result.failure.last.errors).to include(:password_confirmation)
    expect(User.where(email: "lea@example.com")).to be_empty
    expect(Invitation.find_usable(invitation.token)).to eq(invitation)
  end

  it "requires a password for a new account" do
    result = described_class.new.call(token: invitation.token, account: account.merge(password: ""))

    expect(result.failure.first).to eq(:invalid_account)
  end

  it "keeps the link for someone already in the household" do
    member = create(:household_member, household:, role: :member)

    result = described_class.new.call(token: invitation.token, user: member.user)

    expect(result.failure).to eq([ :already_member, household ])
    expect(Invitation.find_usable(invitation.token)).to eq(invitation)
  end

  it "refuses an unknown, used or expired link alike" do
    described_class.new.call(token: invitation.token, user: create(:user))

    expect(described_class.new.call(token: invitation.token, user: create(:user)).failure).to eq([ :unusable ])
    expect(described_class.new.call(token: "nope", user: create(:user)).failure).to eq([ :unusable ])
  end
end
