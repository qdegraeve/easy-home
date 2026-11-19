require "rails_helper"

RSpec.describe Household, type: :model do
  it { is_expected.to validate_presence_of(:name) }

  it "est à l'heure de La Réunion par défaut" do
    expect(described_class.new.time_zone).to eq("Indian/Reunion")
  end

  it "refuse un fuseau horaire inconnu" do
    expect(build(:household, time_zone: "Mars/Olympus")).not_to be_valid
  end

  it "refuse une position hors des bornes ou non numérique, sans erreur en base" do
    expect(build(:household, latitude: "1000", longitude: "55")).not_to be_valid
    expect(build(:household, latitude: "-20.9", longitude: "200")).not_to be_valid
    expect(build(:household, latitude: "abc", longitude: "55")).not_to be_valid
    expect(build(:household, latitude: "-20.9", longitude: "55.45")).to be_valid
  end
end
