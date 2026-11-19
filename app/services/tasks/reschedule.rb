module Tasks
  # Recalcule l'échéance ouverte d'une tâche active depuis sa dernière réalisation (voir Recurrence : une tâche jamais
  # faite part de sa date de début). Sans prochaine échéance (tâche unique déjà faite), l'échéance ouverte disparaît.
  # À appeler dans une transaction, la tâche verrouillée (task.lock!).
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
