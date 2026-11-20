require "rails_helper"

RSpec.describe PlantAnalysisQuestionPolicy do
  subject { described_class.new(user, question) }

  let(:analysis) { create(:plant_analysis, :done) }
  let(:question) { PlantAnalysisQuestion.new(analysis:, status: :failed) }
  let(:plant) { analysis.plant }

  context "for a member of the household" do
    let(:user) { create(:household_member, household: plant.household, role: :member).user }

    it { is_expected.to permit_actions(%i[create ask_again]) }

    context "when the question did not fail" do
      let(:question) { PlantAnalysisQuestion.new(analysis:, status: :done) }

      it { is_expected.to forbid_action(:ask_again) }
    end

    context "when the analysis is not done" do
      before { analysis.update!(status: :failed) }

      it { is_expected.to forbid_actions(%i[create ask_again]) }
    end

    context "when the plant is archived" do
      before { plant.update!(archived_at: Time.current) }

      it { is_expected.to forbid_actions(%i[create ask_again]) }
    end
  end

  context "for a guest of the household" do
    let(:user) { create(:household_member, household: plant.household, role: :guest).user }

    it { is_expected.to forbid_actions(%i[create ask_again]) }
  end
end
