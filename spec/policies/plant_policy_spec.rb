require "rails_helper"

RSpec.describe PlantPolicy do
  subject { described_class.new(user, plant) }

  let(:plant) { create(:plant) }
  let(:actions) { %i[show create update destroy archive restore] }

  %i[owner member].each do |role|
    context "pour un #{role} du foyer" do
      let(:user) { create(:household_member, household: plant.household, role:).user }

      it { is_expected.to permit_actions(actions) }
    end
  end

  context "pour un invité du foyer" do
    let(:user) { create(:household_member, household: plant.household, role: :guest).user }

    it { is_expected.to forbid_actions(actions) }
  end

  context "pour un utilisateur d'un autre foyer" do
    let(:user) { create(:user, :with_household) }

    it { is_expected.to forbid_actions(actions) }
  end

  describe "Scope" do
    it "ne renvoie que les plantes des foyers où l'utilisateur n'est pas invité" do
      user = create(:household_member, household: plant.household, role: :member).user
      guest_plant = create(:plant)
      create(:household_member, user:, household: guest_plant.household, role: :guest)
      create(:plant)

      expect(described_class::Scope.new(user, Plant).resolve).to contain_exactly(plant)
      expect(described_class::Scope.new(nil, Plant).resolve).to be_empty
    end
  end
end
