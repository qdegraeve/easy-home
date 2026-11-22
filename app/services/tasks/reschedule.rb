module Tasks
  # Recomputes the open occurrence of an active task from its last completion (see Recurrence: a task never done
  # starts from its start date). With no next occurrence (one-off task already done), the open occurrence is removed.
  # Never before the day of a miss since that completion: it would be missed again at once (Tasks::MarkMissed).
  # Call inside a transaction, with the task locked (task.lock!).
  class Reschedule
    include Dry::Monads[:result]

    def call(task:)
      return Success(nil) unless task.active?

      last_completed_at = task.occurrences.done.maximum(:completed_at)&.in_time_zone
      due_at = not_before_last_miss(task, task.recurrence.next_due_at(last_completed_at:), last_completed_at)
      pending = task.occurrences.pending.first
      if due_at.nil?
        pending&.destroy!
        return Success(nil)
      end

      occurrence = pending || task.occurrences.build
      occurrence.update!(due_at:)

      Success(occurrence)
    end

    private

    def not_before_last_miss(task, due_at, last_completed_at)
      missed_at = task.occurrences.missed.maximum(:completed_at)&.in_time_zone
      return due_at if due_at.nil? || missed_at.nil? || (last_completed_at && missed_at < last_completed_at)

      [ due_at, missed_at.beginning_of_day ].max
    end
  end
end
