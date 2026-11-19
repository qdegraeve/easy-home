module Tasks
  # Cancels a completion recorded by mistake: it leaves the log and the open occurrence is recomputed from the
  # previous completion.
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
