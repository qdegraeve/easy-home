require "rails_helper"

RSpec.describe TaskPolicy do
  subject { described_class.new(user, task) }

  let(:plant) { create(:plant) }
  let(:task) { create(:task, household: plant.household, subject: plant, template_key: nil) }

  context "for a member of the household" do
    let(:user) { create(:household_member, household: plant.household, role: :member).user }

    it { is_expected.to permit_actions(%i[create update destroy]) }

    context "when the plant is archived" do
      before { plant.update!(archived_at: Time.current) }

      it { is_expected.to forbid_actions(%i[create update]) }
      it { is_expected.to permit_action(:destroy) }
    end

    context "on the watering task (set up from the plant)" do
      let(:task) { create(:task, household: plant.household, subject: plant) }

      it { is_expected.to permit_action(:create) }
      it { is_expected.to forbid_actions(%i[update destroy]) }
    end
  end

  context "for a guest of the household" do
    let(:user) { create(:household_member, household: plant.household, role: :guest).user }

    it { is_expected.to forbid_actions(%i[create update destroy]) }
  end

  context "for a user of another household" do
    let(:user) { create(:user, :with_household) }

    it { is_expected.to forbid_actions(%i[create update destroy]) }
  end

  describe "Scope" do
    it "only returns tasks of households where the user is not a guest" do
      user = create(:household_member, household: plant.household, role: :owner).user
      other = create(:task)
      create(:household_member, user:, household: other.household, role: :guest)

      expect(described_class::Scope.new(user, Task).resolve).to contain_exactly(task)
    end
  end
end
