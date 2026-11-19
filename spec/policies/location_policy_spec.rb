require "rails_helper"

RSpec.describe LocationPolicy do
  subject { described_class.new(user, location) }

  let(:location) { build(:location) }

  context "pour le propriétaire du foyer" do
    let(:user) { create(:household_member, household: location.household, role: :owner).user }

    it { is_expected.to permit_actions(%i[create destroy]) }
  end

  context "pour un membre du foyer" do
    let(:user) { create(:household_member, household: location.household, role: :member).user }

    it { is_expected.to permit_actions(%i[create destroy]) }
  end

  context "pour un invité du foyer" do
    let(:user) { create(:household_member, household: location.household, role: :guest).user }

    it { is_expected.to forbid_actions(%i[create destroy]) }
  end

  context "pour un utilisateur d'un autre foyer" do
    let(:user) { create(:user, :with_household) }

    it { is_expected.to forbid_actions(%i[create destroy]) }
  end
end
