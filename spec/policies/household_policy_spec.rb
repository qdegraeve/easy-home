require "rails_helper"

RSpec.describe HouseholdPolicy do
  subject { described_class.new(user, household) }

  let(:household) { create(:household) }

  context "for the owner of the household" do
    let(:user) { create(:household_member, household:, role: :owner).user }

    it { is_expected.to permit_actions(%i[show edit update new create]) }
  end

  context "for a member of the household" do
    let(:user) { create(:household_member, household:, role: :member).user }

    it { is_expected.to permit_actions(%i[show edit update]) }
  end

  context "for a guest of the household" do
    let(:user) { create(:household_member, household:, role: :guest).user }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_actions(%i[edit update]) }
  end

  context "for a user of another household" do
    let(:user) { create(:user, :with_household) }

    it { is_expected.to forbid_actions(%i[show edit update]) }
    it { is_expected.to permit_actions(%i[new create]) }
  end

  context "without a user" do
    let(:user) { nil }

    it { is_expected.to forbid_actions(%i[show edit update new create]) }
  end

  context "on the class, when the user has no household" do
    subject { described_class.new(create(:user), Household) }

    it { is_expected.to forbid_actions(%i[show edit update]) }
  end

  describe "Scope" do
    it "only returns the households of the user" do
      member = create(:household_member)
      create(:household, name: "Foyer d'un autre")

      expect(described_class::Scope.new(member.user, Household).resolve).to eq([ member.household ])
    end

    it "returns nothing without a user" do
      create(:household)

      expect(described_class::Scope.new(nil, Household).resolve).to be_empty
    end
  end
end
