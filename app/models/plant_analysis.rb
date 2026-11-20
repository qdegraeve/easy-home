# An AI analysis of a plant from one to five of its photos (ADR 0008). It never changes anything by itself: species,
# watering interval and actions are proposals for the user to accept.
class PlantAnalysis < ApplicationRecord
  MAX_PHOTOS = 5

  belongs_to :plant
  belongs_to :requested_by, class_name: "User", optional: true
  has_many :analysis_photos, class_name: "PlantAnalysisPhoto", dependent: :destroy
  has_many :photos, through: :analysis_photos

  enum :status, { pending: "pending", done: "done", failed: "failed" }, validate: true
  enum :health, { ok: "ok", watch: "watch", act: "act" }, prefix: true, validate: { allow_nil: true }
  enum :species_confidence, { low: "low", medium: "medium", high: "high" }, prefix: true, validate: { allow_nil: true }

  validates :user_note, length: { maximum: 1000 }
  validates :watering_interval_days, numericality: { only_integer: true, in: 1..60 }, allow_nil: true
  # On creation only: deleting a photo later leaves its analyses in place.
  validates :photos, length: { in: 1..MAX_PHOTOS }, on: :create

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  # In memory, so it also holds on an analysis that is not saved yet: the AI compares the photos in time order.
  def photos_oldest_first
    photos.sort_by { |photo| [ photo.taken_at, photo.id.to_i ] }
  end
end
