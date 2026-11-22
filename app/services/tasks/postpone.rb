module Tasks
  # Postpones an occurrence due today or late to tomorrow (UX review, mechanism 7), rather than leaving it late. The
  # occurrence is closed as postponed, a discreet line of the journal ("Décalé d'un jour · Sam"), counted neither
  # done nor missed: postponed three times in a row, a task shows that its rhythm is wrong. The same task opens again
  # tomorrow, a new due date (it can be missed again, once). The task is locked like a completion. Returns the
  # postponed occurrence and the new one (the toast undoes it with Tasks::CancelPostponement).
  class Postpone
    include Dry::Monads[:result, :do]

    def call(occurrence:, user:, today: Time.zone.today)
      postponed = nil
      next_occurrence = ActiveRecord::Base.transaction do
        task = occurrence.task
        task.lock!
        occurrence = task.still_open(occurrence.reload) # a page shown before the occurrence was missed
        yield ensure_postponable(task, occurrence, today)

        occurrence.update!(status: :postponed, completed_at: Time.current, completed_by: user)
        postponed = occurrence
        task.occurrences.create!(due_at: (today + 1).in_time_zone)
      end

      Success([ postponed, next_occurrence ])
    end

    private

    def ensure_postponable(task, occurrence, today)
      return Failure[:missed, occurrence] if occurrence.missed?
      return Failure[:not_pending, occurrence] unless occurrence.pending?
      return Failure[:inactive, occurrence] unless task.active?
      return Failure[:not_due, occurrence] if occurrence.due_at.to_date > today

      Success(occurrence)
    end
  end
end
