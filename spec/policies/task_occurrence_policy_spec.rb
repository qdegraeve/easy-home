require "rails_helper"

RSpec.describe TaskOccurrencePolicy do
  subject { described_class.new(user, occurrence) }

  let(:occurrence) { create(:task_occurrence) }
  let(:household) { occurrence.task.household }

  context "pour un membre du foyer" do
    let(:user) { create(:household_member, household:, role: :member).user }

    it { is_expected.to permit_action(:complete) }
  end

  context "pour un invité du foyer" do
    let(:user) { create(:household_member, household:, role: :guest).user }

    it { is_expected.to forbid_action(:complete) }
  end

  context "pour un utilisateur d'un autre foyer" do
    let(:user) { create(:user, :with_household) }

    it { is_expected.to forbid_action(:complete) }
  end

  describe "Scope" do
    it "ne renvoie que les échéances des foyers où l'utilisateur n'est pas invité" do
      user = create(:household_member, household:, role: :owner).user
      other = create(:task_occurrence)
      create(:household_member, user:, household: other.task.household, role: :guest)

      expect(described_class::Scope.new(user, TaskOccurrence).resolve).to contain_exactly(occurrence)
    end
  end
end
