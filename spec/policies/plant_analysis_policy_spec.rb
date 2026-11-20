require "rails_helper"

RSpec.describe PlantAnalysisPolicy do
  subject { described_class.new(user, PlantAnalysis.new(plant:)) }

  let(:plant) { create(:plant) }

  context "for a member of the household" do
    let(:user) { create(:household_member, household: plant.household, role: :member).user }

    it { is_expected.to permit_actions(%i[show new create]) }

    context "when the plant is archived" do
      before { plant.update!(archived_at: Time.current) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_actions(%i[new create]) }
    end
  end

  context "for a guest of the household" do
    let(:user) { create(:household_member, household: plant.household, role: :guest).user }

    it { is_expected.to forbid_actions(%i[show new create]) }
  end

  context "for a user of another household" do
    let(:user) { create(:user, :with_household) }

    it { is_expected.to forbid_actions(%i[show new create]) }
  end
end
