module Tasks
  # Annule une réalisation enregistrée par erreur : elle sort du journal et l'échéance ouverte est recalculée depuis la
  # réalisation précédente.
  class CancelCompletion
    include Dry::Monads[:result, :do]

    def call(occurrence:)
      ActiveRecord::Base.transaction do
        task = occurrence.task
        task.lock!
        occurrence.reload
        yield ensure_done(occurrence)

        occurrence.destroy!
        Tasks::Reschedule.new.call(task:)
      end

      Success(occurrence)
    end

    private

    def ensure_done(occurrence)
      occurrence.done? ? Success(occurrence) : Failure[:not_done, occurrence]
    end
  end
end
