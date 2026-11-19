require "rails_helper"

RSpec.describe Plant, type: :model do
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_length_of(:name).is_at_most(100) }

  it "rejects a location of another household" do
    plant = build(:plant, location: create(:location))

    expect(plant).not_to be_valid
    expect(plant.errors[:location]).to be_present
  end

  it "never changes household" do
    plant = create(:plant)

    expect { plant.update(household: create(:household)) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
  end

  it "deletes its tasks and their history with it" do
    plant = create(:plant, :watered)

    expect { plant.destroy! }.to change(Task, :count).by(-1).and change(TaskOccurrence, :count).by(-2)
  end

  it "loses its location when the location is deleted" do
    location = create(:location)
    plant = create(:plant, household: location.household, location:)

    location.destroy!

    expect(plant.reload.location).to be_nil
  end
end
