class TaskOccurrence < ApplicationRecord
  belongs_to :task
  belongs_to :completed_by, class_name: "User", optional: true

  # missed: past its tolerance without being done (Tasks::MarkMissed); postponed: moved to the next day
  # (Tasks::Postpone). completed_at is then when it was closed.
  enum :status, { pending: "pending", done: "done", missed: "missed", postponed: "postponed" }, validate: true
  # Who closed it: a person (completed_by, nil for an old record) or the rain (Plants::RecordRain, ADR 0015).
  enum :source, { manual: "manual", rain: "rain" }, prefix: :by, validate: true

  validates :due_at, presence: true
  validates :completed_at, presence: true, unless: :pending?

  def self.done_on?(date)
    done.where(completed_at: date.in_time_zone.all_day).exists?
  end
end
