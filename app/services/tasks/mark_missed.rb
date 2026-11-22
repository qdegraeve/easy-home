module Tasks
  # Closes the late occurrences past their tolerance (Tolerance) as missed, a line of the journal, and opens the one
  # that follows (Recurrence#due_after_missed): a sliding task is due again from that day, a one-off task has none
  # left. Run every hour by MarkMissedJob: an occurrence is missed once, each task locked like a completion, so that
  # a "done" at the same moment wins or fails cleanly.
  class MarkMissed
    include Dry::Monads[:result]

    def call(today: Time.zone.today)
      missed = candidates(today).count { |occurrence| mark(occurrence, today) }

      Success(missed)
    end

    private

    # Late ones only (due before today): the tolerance is checked per task, under its lock.
    def candidates(today)
      TaskOccurrence.pending.joins(:task).where(tasks: { active: true })
        .where(due_at: ...today.beginning_of_day).includes(:task).to_a
    end

    def mark(occurrence, today)
      ActiveRecord::Base.transaction do
        task = occurrence.task
        task.lock!
        occurrence.reload
        next false unless occurrence.pending? && task.active? && past_tolerance?(occurrence, task, today)

        occurrence.update!(status: :missed, completed_at: Time.current)
        due_at = task.recurrence.due_after_missed(on: today)
        task.occurrences.create!(due_at:) if due_at
        true
      end
    end

    def past_tolerance?(occurrence, task, today)
      grace_days = task.grace_days
      !grace_days.nil? && occurrence.due_at.to_date + grace_days < today
    end
  end
end