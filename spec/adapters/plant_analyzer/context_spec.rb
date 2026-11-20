require "rails_helper"

RSpec.describe PlantAnalyzer::Context do
  include ActiveSupport::Testing::TimeHelpers

  it "describes the plant, its place and season with a rounded position, never the address" do
    household = create(:household, address: "12 Rue des Exemples 97400 Ville-Exemple", latitude: -20.912345,
                                   longitude: 55.456789, altitude_m: 320)
    location = create(:location, household:, name: "Terrasse", exposure: :partial_shade, sheltered: true)
    plant = create(:plant, :watered, household:, location:, name: "Citronnier", species: "Citrus limon",
                                     species_source: :user, interval_days: 3)
    older = create(:photo, plant:, taken_at: Time.zone.parse("2026-11-02 09:00"))
    newer = create(:photo, plant:, taken_at: Time.zone.parse("2026-11-12 09:00"))
    analysis = create(:plant_analysis, plant:, photos: [ newer, older ], user_note: "Feuilles jaunes en bas.")

    text = described_class.new(analysis, today: Date.new(2026, 11, 16)).to_text

    expect(text).to include(
      "Plant: Citronnier. Species on record: Citrus limon (given by the owner).",
      "around -20.91, 55.46, altitude 320 m",
      "Spot: Terrasse, partial shade, sheltered from the wind.",
      "Current watering: every 3 days.",
      "Today: 2026-11-16 (November, southern hemisphere).",
      "Photos, oldest first: photo 1 on 2026-11-02, photo 2 on 2026-11-12.",
      "Note from the owner: Feuilles jaunes en bas."
    )
    expect(text).not_to include("Rue", "97400", "20.912345")
  end

  it "stays vague when the house has no position and the plant no spot" do
    analysis = create(:plant_analysis)

    text = described_class.new(analysis).to_text

    expect(text).to include("Place: Reunion Island.", "Species on record: unknown.")
    expect(text).not_to include("Spot:", "Note from the owner")
  end
end
