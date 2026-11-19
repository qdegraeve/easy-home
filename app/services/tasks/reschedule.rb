module Tasks
  # Recalcule l'échéance ouverte d'une tâche active depuis sa dernière réalisation (ou maintenant, s'il n'y en a pas).
  # À appeler dans une transaction.
  class Reschedule
    include Dry::Monads[:result]

    def call(task:)
      return Success(nil) unless task.active?

      last_completed_at = task.occurrences.done.maximum(:completed_at)&.in_time_zone || Time.current
      due_at = task.recurrence.next_due_at(last_completed_at:)
      occurrence = task.occurrences.pending.first || task.occurrences.build
      occurrence.update!(due_at:)

      Success(occurrence)
    end
  end
end
