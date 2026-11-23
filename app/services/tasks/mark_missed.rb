module Tasks
  # Closes the late occurrences past their tolerance (Tolerance) as missed: a line of the journal, once per due date.
  # A sliding task is still to do: it is reopened with the same due date ("prévu il y a 5 j"), and that reopened
  # occurrence is never missed again, until done. A one-off task is over (Recurrence#closed_by_miss?). Run every hour
  # by MarkMissedJob; each task is locked like a completion, so that a "done" at the same moment wins or fails cleanly.
  class MarkMissed
    include Dry::Monads[:result]

    def call(today: Time.zone.today)
      missed = candidates(today).count { |occurrence| mark(occurrence, today) }

      Success(missed)
    end

    private

    # Late ones past their tolerance, never reopened ones; checked again under the task lock.
    def candidates(today)
      TaskOccurrence.pending.where(reopened_after_miss: false).joins(:task).where(tasks: { active: true })
        .where(due_at: ...today.beginning_of_day).includes(:task)
        .select { |occurrence| past_tolerance?(occurrence, occurrence.task, today) }
    end

    def mark(occurrence, today)
      ActiveRecord::Base.transaction do
        task = occurrence.task
        task.lock!
        occurrence.reload
        next false unless occurrence.pending? && task.active? && past_tolerance?(occurrence, task, today)

        occurrence.update!(status: :missed, completed_at: Time.current)
        unless task.recurrence.closed_by_miss?
          task.occurrences.create!(due_at: occurrence.due_at, reopened_after_miss: true)
        end
        true
      end
    end

    def past_tolerance?(occurrence, task, today)
      grace_days = task.grace_days
      !occurrence.reopened_after_miss? && !grace_days.nil? && occurrence.due_at.to_date + grace_days < today
    end
  end
end
