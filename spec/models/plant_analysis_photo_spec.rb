require "rails_helper"

RSpec.describe PlantAnalysisPhoto do
  it "takes only a photo of the plant of the analysis" do
    analysis = create(:plant_analysis)
    own = create(:photo, plant: analysis.plant)
    other = create(:photo)

    expect(described_class.new(plant_analysis: analysis, photo: own)).to be_valid
    expect(described_class.new(plant_analysis: analysis, photo: other)).not_to be_valid
  end
end
