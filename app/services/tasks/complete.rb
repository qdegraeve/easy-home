module Tasks
  # Marks an occurrence as done and creates the next one from the task's recurrence (none for a one-off task). The
  # task is locked: a double tap, or a concurrent archive, is serialized and the second one gets a Failure. One
  # completion per day: doing the same task twice on the same day changes nothing to the recurrence and would skew
  # the log. The rain completes a watering too (Plants::RecordRain): no user then.
  class Complete
    include Dry::Monads[:result, :do]

    def call(occurrence:, user:, source: :manual)
      ActiveRecord::Base.transaction do
        task = occurrence.task
        task.lock!
        occurrence = task.still_open(occurrence.reload)
        yield ensure_open(task, occurrence)

        completed_at = Time.current
        occurrence.update!(status: :done, completed_at:, completed_by: user, source:)
        next_due_at = task.recurrence.next_due_at(last_completed_at: completed_at)
        task.occurrences.create!(due_at: next_due_at) if next_due_at
      end

      Success(occurrence)
    end

    private

    def ensure_open(task, occurrence)
      return Failure[:missed, occurrence] if occurrence.missed?
      return Failure[:not_pending, occurrence] unless occurrence.pending?
      return Failure[:inactive, occurrence] unless task.active?
      return Failure[:already_done_today, occurrence] if task.occurrences.done_on?(Time.zone.today)

      Success(occurrence)
    end
  end
end
