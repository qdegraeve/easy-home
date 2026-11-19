module Tasks
  # Marque une échéance comme faite et crée la suivante selon la récurrence de la tâche. Un double appui (deux
  # requêtes simultanées) est sérialisé par le verrou : le second reçoit Failure[:not_pending].
  class Complete
    include Dry::Monads[:result, :do]

    def call(occurrence:, user:)
      ActiveRecord::Base.transaction do
        occurrence.lock!
        yield ensure_open(occurrence)

        completed_at = Time.current
        occurrence.update!(status: :done, completed_at:, completed_by: user)
        task = occurrence.task
        task.occurrences.create!(due_at: task.recurrence.next_due_at(last_completed_at: completed_at))
      end

      Success(occurrence)
    end

    private

    def ensure_open(occurrence)
      return Failure[:not_pending, occurrence] unless occurrence.pending?
      return Failure[:inactive, occurrence] unless occurrence.task.active?

      Success(occurrence)
    end
  end
end
