# A follow-up question on a finished analysis, answered by the AI in plain text (ADR 0008). It may carry a new photo,
# which is also one of the plant's photos.
class PlantAnalysisQuestion < ApplicationRecord
  MAX_PER_ANALYSIS = 10

  belongs_to :analysis, class_name: "PlantAnalysis", foreign_key: :plant_analysis_id, inverse_of: :questions
  belongs_to :asked_by, class_name: "User", optional: true
  belongs_to :photo, optional: true

  enum :status, { pending: "pending", done: "done", failed: "failed" }, validate: true

  validates :body, presence: true, length: { maximum: 1000 }
  validates :answer, length: { maximum: PlantAnalyzer::MAX_ANSWER_LENGTH }

  scope :in_order, -> { order(:created_at, :id) }
end
