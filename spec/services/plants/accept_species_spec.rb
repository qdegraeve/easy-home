require "rails_helper"

RSpec.describe Plants::AcceptSpecies do
  let(:plant) { create(:plant, :watered, species: "Agrume", species_source: :user) }
  let(:analysis) { create(:plant_analysis, :with_proposals, plant:) }

  it "sets the proposed species on the plant, marked as coming from the AI" do
    result = described_class.new.call(analysis:)

    expect(result).to be_success
    expect(plant.reload).to have_attributes(species: "Citrus limon", species_source: "ai")
    expect(analysis).to be_species_accepted
  end

  it "refuses an analysis without a species" do
    analysis.update!(species_name: nil)

    expect(described_class.new.call(analysis:).failure.first).to eq(:not_acceptable)
    expect(plant.reload.species).to eq("Agrume")
  end

  it "refuses an analysis that is not done" do
    analysis.update!(status: :failed)

    expect(described_class.new.call(analysis:).failure.first).to eq(:not_acceptable)
  end

  it "refuses an archived plant" do
    plant.update!(archived_at: Time.current)

    expect(described_class.new.call(analysis:).failure.first).to eq(:subject_archived)
    expect(plant.reload.species).to eq("Agrume")
  end
end
