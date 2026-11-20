require "rails_helper"

RSpec.describe PhotoPolicy do
  subject { described_class.new(user, photo) }

  let(:plant) { create(:plant) }
  let(:photo) { Photo.new(plant:) }

  context "for a member of the household" do
    let(:user) { create(:household_member, household: plant.household, role: :member).user }

    it { is_expected.to permit_actions(%i[show create destroy]) }

    context "when the plant is archived" do
      before { plant.update!(archived_at: Time.current) }

      it { is_expected.to forbid_action(:create) }
      it { is_expected.to permit_actions(%i[show destroy]) }
    end
  end

  context "for a guest of the household" do
    let(:user) { create(:household_member, household: plant.household, role: :guest).user }

    it { is_expected.to forbid_actions(%i[show create destroy]) }
  end

  context "for a user of another household" do
    let(:user) { create(:user, :with_household) }

    it { is_expected.to forbid_actions(%i[show create destroy]) }
  end
end
