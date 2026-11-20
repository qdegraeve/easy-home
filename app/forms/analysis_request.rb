# What the user asks to analyse: one to five photos of the plant (the latest one when none is picked) and an
# optional note for the gardener.
class AnalysisRequest
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :note, :string
  attr_accessor :plant
  attr_writer :photo_ids

  validates :note, length: { maximum: 1000 }
  validate :photos_must_be_chosen_among_the_plant_photos

  def self.model_name
    ActiveModel::Name.new(self, nil, "PlantAnalysis")
  end

  def photo_ids
    Array(@photo_ids).compact_blank.map(&:to_i).uniq
  end

  def photos
    @photos ||= photo_ids.empty? ? plant.photos.limit(1).to_a : plant.photos.where(id: photo_ids).to_a
  end

  private

  def photos_must_be_chosen_among_the_plant_photos
    if photo_ids.any? && photos.size != photo_ids.size
      errors.add(:photo_ids, :invalid)
    elsif photos.empty?
      errors.add(:photo_ids, :blank)
    elsif photos.size > PlantAnalysis::MAX_PHOTOS
      errors.add(:photo_ids, :too_many, count: PlantAnalysis::MAX_PHOTOS)
    end
  end
end
