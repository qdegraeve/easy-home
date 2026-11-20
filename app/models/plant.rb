class Plant < ApplicationRecord
  WATERING_TEMPLATE_KEY = "plant.watering".freeze

  belongs_to :household
  belongs_to :location, optional: true
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

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  def archived?
    archived_at.present?
  end

  def next_watering_at
    watering_task&.pending_occurrence&.due_at
  end

  private

  def location_must_belong_to_household
    return if location.nil? || location.household_id == household_id

    errors.add(:location, :invalid)
  end
end
