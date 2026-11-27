require "rails_helper"

RSpec.describe HouseholdMemberPolicy do
  subject { described_class.new(user, record) }

  let(:household) { create(:household) }
  let(:pending) { create(:invitation, household_member: build(:household_member, household:, user: nil)).household_member }
  let(:joined) { create(:household_member, household:, role: :member) }

  context "for a manager" do
    let(:user) { create(:household_member, household:, role: :manager).user }

    context "on a reserved place" do
      let(:record) { pending }

      it { is_expected.to permit_actions(%i[index new create renew destroy]) }
    end

    context "on a member who joined" do
      let(:record) { joined }

      it { is_expected.to permit_actions(%i[index create]) }
      it { is_expected.to forbid_actions(%i[renew destroy]) }
    end
  end

  context "for a member" do
    let(:user) { create(:household_member, household:, role: :member).user }
    let(:record) { pending }

    it { is_expected.to permit_action(:index) }
    it { is_expected.to forbid_actions(%i[new create renew destroy]) }
  end

  context "for a guest, someone else, or nobody" do
    let(:record) { pending }

    it "forbids everything" do
      [ create(:household_member, household:, role: :guest).user, create(:user, :with_household), nil ].each do |user|
        expect(described_class.new(user, record)).to forbid_actions(%i[index new create renew destroy])
      end
    end
  end

  describe "Scope" do
    it "returns the places of the households the user manages" do
      member = create(:household_member, role: :member)
      create(:household_member)

      expect(described_class::Scope.new(member.user, HouseholdMember).resolve).to eq([ member ])
    end
  end
end
