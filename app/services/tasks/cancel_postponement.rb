module Tasks
  # Cancels a postponement made by mistake ("Annuler" of the toast): the occurrence opened for tomorrow goes away and
  # the postponed one is open again, as before. Too late once tomorrow's occurrence is no longer open (done).
  class CancelPostponement
    include Dry::Monads[:result, :do]

    def call(occurrence:)
      ActiveRecord::Base.transaction do
        task = occurrence.task
        task.lock!
        occurrence.reload
        next_occurrence = yield ensure_cancellable(task, occurrence)

        next_occurrence.destroy!
        occurrence.update!(status: :pending, completed_at: nil, completed_by: nil, source: :manual)
      end

      Success(occurrence)
    end

    private

    def ensure_cancellable(task, occurrence)
      return Failure[:not_postponed, occurrence] unless occurrence.postponed?

      next_occurrence = task.occurrences.pending.first
      done_since = task.occurrences.done.where(completed_at: occurrence.completed_at..).exists?
      next_occurrence && !done_since ? Success(next_occurrence) : Failure[:too_late, occurrence]
    end
  end
end
