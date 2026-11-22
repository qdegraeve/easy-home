class TaskOccurrence < ApplicationRecord
  belongs_to :task
  belongs_to :completed_by, class_name: "User", optional: true

  # missed: past its tolerance without being done (Tasks::MarkMissed); completed_at is then when it was closed.
  enum :status, { pending: "pending", done: "done", missed: "missed" }, validate: true

  validates :due_at, presence: true
  validates :completed_at, presence: true, unless: :pending?

  def self.done_on?(date)
    done.where(completed_at: date.in_time_zone.all_day).exists?
  end
end
