require "rails_helper"

RSpec.describe PlantAnalysisAnswer do
  let(:raw) { FakePlantAnalyzer::ANSWER.deep_dup }

  it "accepts an answer that fits the schema and maps it to analysis attributes" do
    answer = described_class.new(raw)

    expect(answer).to be_valid
    expect(answer.attributes).to include(
      health: "watch", species_name: "Citrus limon", species_common_name: "Citronnier",
      species_confidence: "high", watering_interval_days: 4
    )
    expect(answer.attributes[:actions]).to eq([ raw["actions"].first ])
  end

  {
    "an unknown health" => ->(raw) { raw["health"] = "dying" },
    "a missing species" => ->(raw) { raw.delete("species") },
    "an unknown confidence" => ->(raw) { raw["species"]["confidence"] = "sure" },
    "an interval of 0 days" => ->(raw) { raw["watering_interval_days"] = 0 },
    "an interval as text" => ->(raw) { raw["watering_interval_days"] = "4" },
    "observations over 2000 characters" => ->(raw) { raw["observations"] = "a" * 2001 },
    "more than 5 actions" => ->(raw) { raw["actions"] = Array.new(6) { raw["actions"].first } },
    "an action without title" => ->(raw) { raw["actions"].first["title"] = " " },
    "an action due in 61 days" => ->(raw) { raw["actions"].first["due_in_days"] = 61 },
    "something that is not an object" => ->(raw) { raw.clear }
  }.each do |label, change|
    it "rejects #{label}" do
      change.call(raw)

      expect(described_class.new(raw)).not_to be_valid
    end
  end

  it "rejects an answer that is not a hash" do
    expect(described_class.new("free text")).not_to be_valid
  end
end
