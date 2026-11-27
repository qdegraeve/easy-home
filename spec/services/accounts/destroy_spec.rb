require "rails_helper"

RSpec.describe Accounts::Destroy do
  let(:user) { create(:user, name: "Léa") }

  it "deletes the account, its sessions and phones, and leaves a shared household, keeping what was done" do
    shared = create(:household)
    create(:household_member, household: shared, role: :manager)
    create(:household_member, household: shared, user:, role: :member)
    device = create(:push_device, owner: create(:session, user:))
    task = create(:task, household: shared)
    done = task.occurrences.create!(due_at: Time.current, status: :done, completed_at: Time.current, completed_by: user)

    expect(described_class.new.call(user:, password: "password")).to be_success

    expect(User.exists?(user.id)).to be(false)
    expect(ApplicationPushDevice.exists?(device.id)).to be(false)
    expect(shared.reload.members.joined.count).to eq(1)
    expect(done.reload.completed_by).to be_nil
  end

  it "deletes a household where the person is alone, with what it holds" do
    alone = create(:household_member, user:, role: :manager).household
    plant = create(:plant, :watered, household: alone)

    described_class.new.call(user:, password: "password")

    expect(Household.exists?(alone.id)).to be(false)
    expect(Plant.exists?(plant.id)).to be(false)
  end

  it "refuses a wrong password, and the last manager of a shared household, deleting nothing" do
    shared = create(:household_member, user:, role: :manager).household
    create(:household_member, household: shared, role: :member)
    alone = create(:household_member, user:, role: :manager).household

    expect(described_class.new.call(user:, password: "wrong").failure.first).to eq(:wrong_password)
    expect(described_class.new.call(user:, password: "password").failure.first).to eq(:last_manager)
    expect(Household.exists?(alone.id)).to be(true)
    expect(user.reload).to be_present
    expect(described_class.households_to_hand_over(user)).to eq([ shared ])
    expect(described_class.households_alone(user)).to eq([ alone ])
  end
end
