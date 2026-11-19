require "rails_helper"

RSpec.describe Household, type: :model do
  it { is_expected.to validate_presence_of(:name) }

  it "est à l'heure de La Réunion par défaut" do
    expect(described_class.new.time_zone).to eq("Indian/Reunion")
  end

  it "refuse un fuseau horaire inconnu" do
    expect(build(:household, time_zone: "Mars/Olympus")).not_to be_valid
  end
end
