require "rails_helper"

RSpec.describe HouseholdPolicy do
  subject { described_class.new(user, household) }

  let(:household) { create(:household) }

  context "pour un membre du foyer" do
    let(:user) { create(:household_member, household:).user }

    it { is_expected.to permit_actions(%i[show new create]) }
  end

  context "pour un utilisateur d'un autre foyer" do
    let(:user) { create(:user, :with_household) }

    it { is_expected.to forbid_action(:show) }
    it { is_expected.to permit_actions(%i[new create]) }
  end

  context "sans utilisateur" do
    let(:user) { nil }

    it { is_expected.to forbid_actions(%i[show new create]) }
  end

  describe "Scope" do
    it "ne renvoie que les foyers de l'utilisateur" do
      member = create(:household_member)
      create(:household, name: "Foyer d'un autre")

      expect(described_class::Scope.new(member.user, Household).resolve).to eq([ member.household ])
    end

    it "ne renvoie rien sans utilisateur" do
      create(:household)

      expect(described_class::Scope.new(nil, Household).resolve).to be_empty
    end
  end
end
