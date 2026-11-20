require "rails_helper"

RSpec.describe PlantAnalysisPolicy do
  subject { described_class.new(user, PlantAnalysis.new(plant:)) }

  let(:plant) { create(:plant) }

  context "for a member of the household" do
    let(:user) { create(:household_member, household: plant.household, role: :member).user }

    it { is_expected.to permit_actions(%i[show new create]) }
    it { is_expected.to forbid_action(:accept) }

    context "when the analysis is done" do
      subject { described_class.new(user, PlantAnalysis.new(plant:, status: :done)) }

      it { is_expected.to permit_action(:accept) }
    end

    context "when the plant is archived" do
      subject { described_class.new(user, PlantAnalysis.new(plant:, status: :done)) }

      before { plant.update!(archived_at: Time.current) }

      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_actions(%i[new create accept]) }
    end
  end

  context "for a guest of the household" do
    let(:user) { create(:household_member, household: plant.household, role: :guest).user }

    it { is_expected.to forbid_actions(%i[show new create accept]) }
  end

  context "for a user of another household" do
    let(:user) { create(:user, :with_household) }

    it { is_expected.to forbid_actions(%i[show new create accept]) }
  end
end
