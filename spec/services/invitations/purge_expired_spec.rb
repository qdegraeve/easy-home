require "rails_helper"

RSpec.describe Invitations::PurgeExpired do
  include ActiveSupport::Testing::TimeHelpers

  it "frees the places of expired invitations only" do
    expired = create(:invitation)
    open = travel_to(3.days.from_now) { create(:invitation) }
    accepted = create(:invitation)
    Invitations::Accept.new.call(token: accepted.token, user: create(:user, email: accepted.email))

    renewed = create(:invitation)

    travel_to(8.days.from_now) do
      Invitations::Renew.new.call(invitation: renewed)
      expect(described_class.new.call.value!).to eq(1)
    end

    expect(renewed.household_member.reload).to be_present

    expect(HouseholdMember.exists?(expired.household_member_id)).to be(false)
    expect(Invitation.exists?(expired.id)).to be(false)
    expect(open.household_member.reload).to be_present
    expect(accepted.household_member.reload.user).to be_present
  end
end
