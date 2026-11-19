module Tasks
  # Marque une échéance comme faite et crée la suivante selon la récurrence de la tâche (aucune pour une tâche unique). La tâche est verrouillée :
  # un double appui, ou un archivage simultané, est sérialisé et le second reçoit un Failure. Une seule réalisation
  # par jour : refaire la même tâche le même jour ne change rien à la récurrence et fausserait le journal.
  class Complete
    include Dry::Monads[:result, :do]

    def call(occurrence:, user:)
      ActiveRecord::Base.transaction do
        task = occurrence.task
        task.lock!
        occurrence.reload
        yield ensure_open(task, occurrence)

        completed_at = Time.current
        occurrence.update!(status: :done, completed_at:, completed_by: user)
        next_due_at = task.recurrence.next_due_at(last_completed_at: completed_at)
        task.occurrences.create!(due_at: next_due_at) if next_due_at
      end

      Success(occurrence)
    end

    private

    def ensure_open(task, occurrence)
      return Failure[:not_pending, occurrence] unless occurrence.pending?
      return Failure[:inactive, occurrence] unless task.active?
      return Failure[:already_done_today, occurrence] if task.occurrences.done_on?(Time.zone.today)

      Success(occurrence)
    end
  end
end
