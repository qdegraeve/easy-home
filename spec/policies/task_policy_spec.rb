require "rails_helper"

RSpec.describe TaskPolicy do
  subject { described_class.new(user, task) }

  let(:plant) { create(:plant) }
  let(:task) { create(:task, household: plant.household, subject: plant, template_key: nil) }

  context "pour un membre du foyer" do
    let(:user) { create(:household_member, household: plant.household, role: :member).user }

    it { is_expected.to permit_actions(%i[create update destroy]) }

    context "quand la plante est archivée" do
      before { plant.update!(archived_at: Time.current) }

      it { is_expected.to forbid_actions(%i[create update]) }
      it { is_expected.to permit_action(:destroy) }
    end

    context "sur la tâche d'arrosage (réglée depuis la plante)" do
      let(:task) { create(:task, household: plant.household, subject: plant) }

      it { is_expected.to permit_action(:create) }
      it { is_expected.to forbid_actions(%i[update destroy]) }
    end
  end

  context "pour un invité du foyer" do
    let(:user) { create(:household_member, household: plant.household, role: :guest).user }

    it { is_expected.to forbid_actions(%i[create update destroy]) }
  end

  context "pour un utilisateur d'un autre foyer" do
    let(:user) { create(:user, :with_household) }

    it { is_expected.to forbid_actions(%i[create update destroy]) }
  end

  describe "Scope" do
    it "ne renvoie que les tâches des foyers où l'utilisateur n'est pas invité" do
      user = create(:household_member, household: plant.household, role: :owner).user
      other = create(:task)
      create(:household_member, user:, household: other.household, role: :guest)

      expect(described_class::Scope.new(user, Task).resolve).to contain_exactly(task)
    end
  end
end
