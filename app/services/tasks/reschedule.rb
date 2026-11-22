module Tasks
  # Recomputes the open occurrence of an active task from its last completion (see Recurrence: a task never done
  # starts from its start date). With no next occurrence (one-off task already done), the open occurrence is removed.
  # Never past the tolerance (Tolerance.earliest): restored, edited or cancelled, a task is not missed at once. A
  # one-off task missed is over, like once done. Never before the day after a postponement since the last completion
  # (Tasks::Postpone): the journal says it was moved.
  # Call inside a transaction, with the task locked (task.lock!).
  class Reschedule
    include Dry::Monads[:result]

    def call(task:)
      return Success(nil) unless task.active?

      last_completed_at = task.occurrences.done.maximum(:completed_at)&.in_time_zone
      due_at = task.due_within_tolerance(task.recurrence.next_due_at(last_completed_at:))
      due_at = after_last_postponement(task, due_at, last_completed_at)
      due_at = nil if task.recurrence.closed_by_miss? && task.occurrences.missed.exists?
      pending = task.occurrences.pending.first
      if due_at.nil?
        pending&.destroy!
        return Success(nil)
      end

      occurrence = pending || task.occurrences.build
      # Moved, it is a new due date: it can be missed again, once (Tasks::MarkMissed).
      occurrence.update!(due_at:, reopened_after_miss: occurrence.reopened_after_miss && occurrence.due_at == due_at)

      Success(occurrence)
    end

    private

    def after_last_postponement(task, due_at, last_completed_at)
      postponed_at = task.occurrences.postponed.maximum(:completed_at)&.in_time_zone
      return due_at if due_at.nil? || postponed_at.nil? || (last_completed_at && postponed_at < last_completed_at)

      [ due_at, postponed_at.to_date.next_day.in_time_zone ].max
    end
  end
end
