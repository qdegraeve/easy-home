class Plant < ApplicationRecord
  WATERING_TEMPLATE_KEY = "plant.watering".freeze

  belongs_to :household
  belongs_to :location, optional: true
  # The face of the plant, chosen among its photos (otherwise the latest one: #face).
  belongs_to :cover_photo, class_name: "Photo", optional: true
  has_many :tasks, as: :subject, dependent: :destroy
  has_many :photos, -> { order(taken_at: :desc, id: :desc) }, dependent: :destroy, inverse_of: :plant
  has_many :analyses, class_name: "PlantAnalysis", dependent: :destroy
  has_one :watering_task, -> { where(template_key: WATERING_TEMPLATE_KEY) }, class_name: "Task", as: :subject

  # A plant never changes household: its tasks carry the same household (see ADR 0010).
  attr_readonly :household_id

  enum :species_source, { user: "user", ai: "ai" }, prefix: :species_from, validate: { allow_nil: true }

  validates :name, presence: true, length: { maximum: 100 }
  validates :species, length: { maximum: 100 }
  validate :location_must_belong_to_household
  validate :cover_photo_must_be_one_of_its_photos

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  def archived?
    archived_at.present?
  end

  def face
    cover_photo || photos.first
  end

  def next_watering_at
    watering_task&.pending_occurrence&.due_at
  end

  # The growing conditions of the plant's place, as recorded on an analysis: a change makes its advice doubtful. The
  # name of the location does not count (renaming it changes nothing for the plant).
  def place
    { "exposure" => location&.exposure, "sheltered" => location&.sheltered? || false }
  end

  # The place of the last finished analysis and the current one, when they differ (UX review, "Changement
  # d'emplacement et analyses"). Nil when they match, or when the analysis predates the recording of places. Moving
  # the plant back to its former place clears it.
  def place_change_since_analysis
    analysis = analyses.select(&:done?).max_by { |candidate| [ candidate.created_at, candidate.id ] }
    return if analysis&.place.nil? || analysis.place == place

    [ analysis.place, place ]
  end

  private

  def cover_photo_must_be_one_of_its_photos
    return if cover_photo.nil? || cover_photo.plant_id == id

    errors.add(:cover_photo, :invalid)
  end

  def location_must_belong_to_household
    return if location.nil? || location.household_id == household_id

    errors.add(:location, :invalid)
  end
end
