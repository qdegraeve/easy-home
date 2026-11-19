require "rails_helper"

RSpec.describe TaskOccurrencePolicy do
  subject { described_class.new(user, occurrence) }

  let(:occurrence) { create(:task_occurrence) }
  let(:household) { occurrence.task.household }

  context "for a member of the household" do
    let(:user) { create(:household_member, household:, role: :member).user }

    it { is_expected.to permit_action(:complete) }
  end

  context "for a guest of the household" do
    let(:user) { create(:household_member, household:, role: :guest).user }

    it { is_expected.to forbid_action(:complete) }
  end

  context "for a user of another household" do
    let(:user) { create(:user, :with_household) }

    it { is_expected.to forbid_action(:complete) }
  end

  describe "Scope" do
    it "only returns occurrences of households where the user is not a guest" do
      user = create(:household_member, household:, role: :owner).user
      other = create(:task_occurrence)
      create(:household_member, user:, household: other.task.household, role: :guest)

      expect(described_class::Scope.new(user, TaskOccurrence).resolve).to contain_exactly(occurrence)
    end
  end
end
