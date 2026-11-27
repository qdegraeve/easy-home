require "rails_helper"

RSpec.describe LocationPolicy do
  subject { described_class.new(user, location) }

  let(:location) { build(:location) }

  context "for a manager of the household" do
    let(:user) { create(:household_member, household: location.household, role: :manager).user }

    it { is_expected.to permit_actions(%i[create destroy]) }
  end

  context "for a member of the household" do
    let(:user) { create(:household_member, household: location.household, role: :member).user }

    it { is_expected.to permit_actions(%i[create destroy]) }
  end

  context "for a guest of the household" do
    let(:user) { create(:household_member, household: location.household, role: :guest).user }

    it { is_expected.to forbid_actions(%i[create destroy]) }
  end

  context "for a user of another household" do
    let(:user) { create(:user, :with_household) }

    it { is_expected.to forbid_actions(%i[create destroy]) }
  end
end
