require "rails_helper"

RSpec.describe EquipmentPolicy do
  subject { described_class.new(user, equipment) }

  let(:equipment) { create(:equipment) }
  let(:actions) { %i[show create new update edit destroy] }

  context "for a member of the household" do
    let(:user) { create(:household_member, household: equipment.household, role: :member).user }

    it { is_expected.to permit_actions(actions) }
  end

  context "for a guest of the household" do
    let(:user) { create(:household_member, household: equipment.household, role: :guest).user }

    it { is_expected.to forbid_actions(actions) }
  end

  context "for a user of another household" do
    let(:user) { create(:user, :with_household) }

    it { is_expected.to forbid_actions(actions) }
  end

  it "scopes to the households the user manages" do
    member = create(:household_member, household: equipment.household, role: :member).user
    create(:equipment)

    expect(described_class::Scope.new(member, Equipment).resolve).to eq([ equipment ])
  end
end
