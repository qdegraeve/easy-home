require "rails_helper"

RSpec.describe Equipment, type: :model do
  include ActiveJob::TestHelper

  it_behaves_like "a task subject" do
    subject { create(:equipment) }
  end

  it_behaves_like "a photo subject" do
    subject { create(:equipment) }
  end

  it "is named after its kind when no name is typed, and keeps a typed one trimmed" do
    expect(create(:equipment, kind: "water_heater", name: " ")).to have_attributes(name: "Chauffe-eau")
    expect(create(:equipment, kind: "air_conditioner", name: " Clim chambre ").name).to eq("Clim chambre")
  end

  it "accepts only a kind of the catalogue, and notes of a reasonable length" do
    expect(build(:equipment, kind: "spaceship")).not_to be_valid
    expect(build(:equipment, notes: "a" * (described_class::NOTES_MAX + 1))).not_to be_valid
    expect(build(:equipment, notes: "  ")).to have_attributes(notes: nil)
  end

  it "never changes household" do
    equipment = create(:equipment)

    expect { equipment.update!(household: create(:household)) }.to raise_error(ActiveRecord::ActiveRecordError)
  end
end
