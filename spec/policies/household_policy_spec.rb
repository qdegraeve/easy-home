require "rails_helper"

RSpec.describe HouseholdPolicy do
  subject { described_class.new(user, household) }

  let(:household) { create(:household) }

  context "pour le propriétaire du foyer" do
    let(:user) { create(:household_member, household:, role: :owner).user }

    it { is_expected.to permit_actions(%i[show edit update new create]) }
  end

  context "pour un membre du foyer" do
    let(:user) { create(:household_member, household:, role: :member).user }

    it { is_expected.to permit_actions(%i[show edit update]) }
  end

  context "pour un invité du foyer" do
    let(:user) { create(:household_member, household:, role: :guest).user }

    it { is_expected.to permit_action(:show) }
    it { is_expected.to forbid_actions(%i[edit update]) }
  end

  context "pour un utilisateur d'un autre foyer" do
    let(:user) { create(:user, :with_household) }

    it { is_expected.to forbid_actions(%i[show edit update]) }
    it { is_expected.to permit_actions(%i[new create]) }
  end

  context "sans utilisateur" do
    let(:user) { nil }

    it { is_expected.to forbid_actions(%i[show edit update new create]) }
  end

  context "sur la classe, quand l'utilisateur n'a pas de foyer" do
    subject { described_class.new(create(:user), Household) }

    it { is_expected.to forbid_actions(%i[show edit update]) }
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
