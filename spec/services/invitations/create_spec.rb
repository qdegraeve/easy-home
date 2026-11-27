require "rails_helper"

RSpec.describe Invitations::Create do
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household) }
  let(:manager) { create(:household_member, household:, role: :manager).user }

  it "reserves a place with its role and a link valid 7 days" do
    travel_to(Time.zone.parse("2026-11-27 10:00")) do
      invitation = described_class.new.call(
        household:, created_by: manager, params: { role: "manager", invitee_name: " Léa " }
      ).value!

      expect(invitation.household_member).to have_attributes(user: nil, role: "manager", invitee_name: "Léa")
      expect(invitation).to have_attributes(created_by: manager, expires_at: Time.zone.parse("2026-12-04 10:00"))
      expect(Invitation.find_usable(invitation.token)).to eq(invitation)
    end
  end

  it "refuses an unknown role, and reserves nothing" do
    %w[owner admin].each do |role|
      result = described_class.new.call(household:, created_by: manager, params: { role: })

      expect(result.failure.first).to eq(:invalid)
      expect(result.failure.last.errors).to include(:role)
    end
    expect(household.members.where(user: nil)).to be_empty
  end

  it "does not count a reserved place as a member" do
    described_class.new.call(household:, created_by: manager, params: { role: "member" })

    expect(household.members.joined.map(&:user)).to eq([ manager ])
    expect(household.members.invited.count).to eq(1)
  end

  it "reserves a guest's place with what is opened to them, ready when they join" do
    plant = create(:plant, household:)
    invitation = described_class.new.call(
      household:, created_by: manager, params: { role: "guest" },
      access: { subjects: [ "Plant:#{plant.id}" ], ends_on: "2027-01-05" }
    ).value!

    expect(invitation.household_member).to have_attributes(role: "guest", access_ends_on: Date.new(2027, 1, 5))
    expect(invitation.household_member.guest_accesses.map(&:subject)).to eq([ plant ])
  end
end
