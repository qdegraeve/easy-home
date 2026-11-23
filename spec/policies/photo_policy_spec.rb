require "rails_helper"

RSpec.describe PhotoPolicy do
  subject { described_class.new(user, photo) }

  let(:plant) { create(:plant) }
  let(:photo) { Photo.new(subject: plant) }

  context "for a member of the household" do
    let(:user) { create(:household_member, household: plant.household, role: :member).user }

    it { is_expected.to permit_actions(%i[show create update destroy]) }

    context "when the plant is archived" do
      before { plant.update!(archived_at: Time.current) }

      it { is_expected.to forbid_action(:create) }
      it { is_expected.to permit_actions(%i[show update destroy]) }
    end
  end

  context "for a guest of the household" do
    let(:user) { create(:household_member, household: plant.household, role: :guest).user }

    it { is_expected.to forbid_actions(%i[show create update destroy]) }
  end

  context "for a user of another household" do
    let(:user) { create(:user, :with_household) }

    it { is_expected.to forbid_actions(%i[show create update destroy]) }
  end

  context "without a known subject" do
    let(:user) { create(:household_member, household: plant.household, role: :member).user }
    let(:photo) { Photo.new(subject: nil) }

    it { is_expected.to forbid_actions(%i[show create update destroy]) }
  end

  describe "photos of a task and of an equipment" do
    let(:member) { create(:household_member, household: plant.household, role: :member).user }
    let(:guest) { create(:household_member, household: plant.household, role: :guest).user }

    def policy(user, subject)
      described_class.new(user, Photo.new(subject:))
    end

    it "lets a member see and change the photos of a manual task, and only see those of a watering" do
      pruning = create(:task, household: plant.household, subject: plant, template_key: nil)

      expect(policy(member, pruning)).to permit_actions(%i[show create update destroy])
      expect(policy(member, plant.watering_task || create(:task, household: plant.household, subject: plant)))
        .to permit_action(:show).and forbid_actions(%i[create update destroy])
    end

    it "keeps the photos of a task of an archived plant visible and deletable, with no new one" do
      pruning = create(:task, household: plant.household, subject: plant, template_key: nil)
      plant.update!(archived_at: Time.current)

      expect(policy(member, pruning)).to permit_actions(%i[show destroy]).and forbid_actions(%i[create update])
    end

    it "takes no new photo on a stopped task" do
      stopped = create(:task, household: plant.household, subject: nil, template_key: nil, active: false)

      expect(policy(member, stopped)).to forbid_action(:create)
    end

    it "lets a member manage the photos of an equipment, and neither a guest nor another household" do
      equipment = create(:equipment, household: plant.household)

      expect(policy(member, equipment)).to permit_actions(%i[show create update destroy])
      expect(policy(guest, equipment)).to forbid_actions(%i[show create update destroy])
      expect(policy(create(:user, :with_household), equipment)).to forbid_actions(%i[show create update destroy])
    end
  end
end
