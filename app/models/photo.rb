# A dated photo of a subject: a plant, an equipment, or a task (shown in its sheet with how to do it), ADR 0016.
class Photo < ApplicationRecord
  SUBJECT_TYPES = %w[Plant Equipment Task].freeze

  # The former plant_id, replaced by the subject; dropped later (RequireSubjectOfPhotos).
  self.ignored_columns += [ "plant_id" ]

  belongs_to :subject, polymorphic: true
  has_many :analysis_photos, class_name: "PlantAnalysisPhoto", dependent: :destroy
  has_many :analysis_questions, class_name: "PlantAnalysisQuestion", dependent: :nullify
  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 320, 320 ]
    attachable.variant :large, resize_to_limit: [ 1600, 1600 ]
  end

  validates :subject_type, inclusion: { in: SUBJECT_TYPES }
  validates :taken_at, presence: true, comparison: { less_than_or_equal_to: -> { Time.current }, message: :in_future }
  validates :image, presence: true

  def of?(record)
    subject_type == record.class.polymorphic_name && subject_id == record.id
  end
end
