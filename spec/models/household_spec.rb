require "rails_helper"

RSpec.describe Household, type: :model do
  it { is_expected.to validate_presence_of(:name) }

  it "uses the Reunion time zone by default" do
    expect(described_class.new.time_zone).to eq("Indian/Reunion")
  end

  it "rejects an unknown time zone" do
    expect(build(:household, time_zone: "Mars/Olympus")).not_to be_valid
  end

  it "rejects an out of range or non numeric position, without a database error" do
    expect(build(:household, latitude: "1000", longitude: "55")).not_to be_valid
    expect(build(:household, latitude: "-20.9", longitude: "200")).not_to be_valid
    expect(build(:household, latitude: "abc", longitude: "55")).not_to be_valid
    expect(build(:household, latitude: "-20.9", longitude: "55.45")).to be_valid
  end
end
