class PlantAnalysisPhoto < ApplicationRecord
  belongs_to :plant_analysis
  belongs_to :photo

  validates :photo_id, uniqueness: { scope: :plant_analysis_id }
end
