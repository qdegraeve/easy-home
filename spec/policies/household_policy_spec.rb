require "rails_helper"

RSpec.describe HouseholdPolicy do
  subject { described_class.new(user, household) }

  let(:household) { create(:household) }

  context "pour un membre du foyer" do
    let(:user) { create(:membership, household:).user }

    it { is_expected.to permit_action(:show) }
  end

  context "pour un utilisateur d'un autre foyer" do
    let(:user) { create(:user, :with_household) }

    it { is_expected.to forbid_action(:show) }
  end

  context "sans utilisateur" do
    let(:user) { nil }

    it { is_expected.to forbid_action(:show) }
  end
end
