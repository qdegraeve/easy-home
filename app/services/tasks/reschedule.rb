module Tasks
  # Recomputes the open occurrence of an active task from its last completion (see Recurrence: a task never done
  # starts from its start date). With no next occurrence (one-off task already done), the open occurrence is removed.
  # Call inside a transaction, with the task locked (task.lock!).
  class Reschedule
    include Dry::Monads[:result]

    def call(task:)
      return Success(nil) unless task.active?

      last_completed_at = task.occurrences.done.maximum(:completed_at)&.in_time_zone
      due_at = task.recurrence.next_due_at(last_completed_at:)
      pending = task.occurrences.pending.first
      if due_at.nil?
        pending&.destroy!
        return Success(nil)
      end

      occurrence = pending || task.occurrences.build
      occurrence.update!(due_at:)

      Success(occurrence)
    end
  end
end
