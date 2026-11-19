class TaskOccurrence < ApplicationRecord
  belongs_to :task
  belongs_to :completed_by, class_name: "User", optional: true

  enum :status, { pending: "pending", done: "done" }, validate: true

  validates :due_at, presence: true
  validates :completed_at, presence: true, if: :done?
end
