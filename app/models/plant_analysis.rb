# An AI analysis of a plant from one to five of its photos (ADR 0008). It never changes anything by itself: species,
# watering interval and actions are proposals for the user to accept.
class PlantAnalysis < ApplicationRecord
  MAX_PHOTOS = 5

  belongs_to :plant
  belongs_to :requested_by, class_name: "User", optional: true
  has_many :analysis_photos, class_name: "PlantAnalysisPhoto", dependent: :destroy
  has_many :photos, through: :analysis_photos
  has_many :questions, -> { in_order }, class_name: "PlantAnalysisQuestion", dependent: :destroy,
    inverse_of: :analysis

  enum :status, { pending: "pending", done: "done", failed: "failed" }, validate: true
  enum :health, { ok: "ok", watch: "watch", act: "act" }, prefix: true, validate: { allow_nil: true }
  enum :species_confidence, { low: "low", medium: "medium", high: "high" }, prefix: true, validate: { allow_nil: true }

  validates :user_note, length: { maximum: 1000 }
  validates :watering_interval_days, numericality: { only_integer: true, in: 1..60 }, allow_nil: true
  # On creation only: deleting a photo later leaves its analyses in place.
  validates :photos, length: { in: 1..MAX_PHOTOS }, on: :create

  scope :recent_first, -> { order(created_at: :desc, id: :desc) }

  # The species and the interval show as accepted while the plant matches them, whoever set them. An action is
  # accepted once, when it becomes a task.
  def species_accepted?
    plant.species == species_name
  end

  def watering_accepted?
    plant.watering_task&.recurrence&.interval_days == watering_interval_days
  end

  def action_accepted?(index)
    applied_action_indexes.include?(index)
  end

  # Proposals not taken yet (species, watering interval, actions): the summary on the plant page invites to see them.
  def open_proposals_count
    [ species_name && !species_accepted?, watering_interval_days && !watering_accepted? ].count(true) +
      actions.each_index.count { |index| !action_accepted?(index) }
  end

  # In memory, so it also holds on an analysis that is not saved yet: the AI compares the photos in time order.
  def photos_oldest_first
    photos.sort_by { |photo| [ photo.taken_at, photo.id.to_i ] }
  end
end
