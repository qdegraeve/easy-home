require "rails_helper"

RSpec.describe Invitations::Accept do
  let(:invitation) { create(:invitation, email: "lea@example.com") }
  let(:household) { invitation.household_member.household }
  let(:account) { { name: "Léa", password: "une phrase de passe", password_confirmation: "une phrase de passe" } }

  it "gives the place to the signed-in user of the invited address, and uses the link up" do
    user = create(:user, email: "lea@example.com")

    member = described_class.new.call(token: invitation.token, user:).value!

    expect(member).to have_attributes(user:, household:, role: "member")
    expect(Invitation.find_usable(invitation.token)).to be_nil
  end

  it "refuses another account than the invited address, keeping the link" do
    result = described_class.new.call(token: invitation.token, user: create(:user, email: "autre@example.com"))

    expect(result.failure).to eq([ :other_account, invitation ])
    expect(Invitation.find_usable(invitation.token)).to eq(invitation)
  end

  it "creates the account of the invited address, whatever the form says, ready to use" do
    forged = account.merge(email: "autre@example.com")
    member = described_class.new.call(token: invitation.token, account: forged).value!

    expect(member.user).to have_attributes(name: "Léa", email: "lea@example.com")
    expect(member.user.authenticate("une phrase de passe")).to be_truthy
  end

  it "creates nothing from an invalid account, and keeps the link" do
    result = described_class.new.call(token: invitation.token, account: account.merge(password_confirmation: "autre"))

    expect(result.failure.first).to eq(:invalid_account)
    expect(User.where(email: "lea@example.com")).to be_empty
    expect(Invitation.find_usable(invitation.token)).to eq(invitation)
  end

  it "requires the confirmation of the password" do
    result = described_class.new.call(token: invitation.token, account: account.except(:password_confirmation))

    expect(result.failure.first).to eq(:invalid_account)
  end

  it "requires a password of 15 characters at least, not easy to guess" do
    [ "", "trop court", "aaaaaaaaaaaaaaaaaaaa" ].each do |password|
      weak = account.merge(password:, password_confirmation: password)

      expect(described_class.new.call(token: invitation.token, account: weak).failure.first).to eq(:invalid_account)
    end
  end

  it "keeps the link for someone already in the household" do
    member = create(:household_member, household:, role: :member, user: create(:user, email: "lea@example.com"))
    result = described_class.new.call(token: invitation.token, user: member.user)

    expect(result.failure).to eq([ :already_member, household ])
    expect(Invitation.find_usable(invitation.token)).to eq(invitation)
  end

  it "refuses an unknown, used or expired link alike" do
    described_class.new.call(token: invitation.token, account:)

    expect(described_class.new.call(token: invitation.token, account:).failure).to eq([ :unusable ])
    expect(described_class.new.call(token: "nope", account:).failure).to eq([ :unusable ])
  end
end
