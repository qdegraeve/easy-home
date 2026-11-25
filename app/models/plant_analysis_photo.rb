class PlantAnalysisPhoto < ApplicationRecord
  belongs_to :plant_analysis
  belongs_to :photo

  validates :photo_id, uniqueness: { scope: :plant_analysis_id }
  validate :photo_must_be_of_the_plant

  private

  # Without a foreign key from a photo to its plant, the analysis only takes photos of its own plant.
  def photo_must_be_of_the_plant
    errors.add(:photo, :invalid) if photo && plant_analysis && !photo.of?(plant_analysis.plant)
  end
end
