module Tasks
  # Closes the late occurrences past their tolerance (Tolerance) as missed: a line of the journal, once per due date.
  # Then, by Tolerance.after_miss: a task still to do is reopened with the same due date ("prévu il y a 5 j"), never
  # missed again until done (a watering, a flexible task on fixed dates); a fixed task that must not be missed opens
  # the next date of its rule (a collection is not caught up); a one-off task is over. Run every hour by
  # MarkMissedJob; each task is locked like a completion, so that a "done" at the same moment wins or fails cleanly.
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
        .where.not(tasks: { importance: "flexible", recurrence_type: "once" }) # never missed
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
        follow_up(task, occurrence, today)
        true
      end
    end

    def follow_up(task, missed, today)
      case task.after_miss
      when :reopen then task.occurrences.create!(due_at: missed.due_at, reopened_after_miss: true)
      when :advance
        last_completed_at = task.occurrences.done.maximum(:completed_at)&.in_time_zone
        next_due_at = task.recurrence.next_due_at(last_completed_at:, last_due_on: missed.due_at.to_date,
                                                  not_before: today)
        task.occurrences.create!(due_at: next_due_at) if next_due_at
      end
    end

    def past_tolerance?(occurrence, task, today)
      grace_days = task.grace_days
      !occurrence.reopened_after_miss? && !grace_days.nil? && occurrence.due_at.to_date + grace_days < today
    end
  end
end
