module Tasks
  # Recomputes the open occurrence of an active task from its history (see Recurrence: a task never done starts from
  # its start date). With no next occurrence (one-off task already done, or missed when it must not be), the open
  # occurrence is removed. Never before the day after a postponement since the last completion (Tasks::Postpone): the
  # journal says it was moved.
  # - Sliding and one-off: from the last completion, never past the tolerance (Tolerance.earliest): restored, edited
  #   or cancelled, a task is not missed at once.
  # - Fixed dates: the rule replayed from the last done or missed occurrence, as Tasks::Complete and
  #   Tasks::MarkMissed did (Tolerance.after_miss): a flexible task missed last is reopened on its date, one that must
  #   not be missed goes on with the next date of its rule.
  # Call inside a transaction, with the task locked (task.lock!).
  class Reschedule
    include Dry::Monads[:result]

    def call(task:)
      return Success(nil) unless task.active?

      last_completed_at = task.occurrences.done.maximum(:completed_at)&.in_time_zone
      due_at, reopened = if task.fixed?
        fixed_due(task, last_completed_at)
      else
        [ dated_due(task, last_completed_at), false ]
      end
      due_at = after_last_postponement(task, due_at, last_completed_at)
      pending = task.occurrences.pending.first
      if due_at.nil?
        pending&.destroy!
        return Success(nil)
      end

      occurrence = pending || task.occurrences.build
      # Moved, it is a new due date: it can be missed again, once (Tasks::MarkMissed).
      kept = occurrence.reopened_after_miss && occurrence.due_at == due_at
      occurrence.update!(due_at:, reopened_after_miss: reopened || kept)

      Success(occurrence)
    end

    private

    def dated_due(task, last_completed_at)
      return nil if task.after_miss == :close && task.occurrences.missed.exists?

      task.due_within_tolerance(task.recurrence.next_due_at(last_completed_at:))
    end

    # [due_at, reopened after a miss]
    def fixed_due(task, last_completed_at)
      last_closed = task.occurrences.where(status: %i[done missed]).order(completed_at: :desc, id: :desc).first
      return [ last_closed.due_at, true ] if last_closed&.missed? && task.after_miss == :reopen

      due_at = task.recurrence.next_due_at(
        last_completed_at:,
        last_due_on: last_closed&.due_at&.to_date,
        not_before: Time.zone.today - task.grace_days.to_i
      )
      [ due_at, false ]
    end

    def after_last_postponement(task, due_at, last_completed_at)
      postponed_at = task.occurrences.postponed.maximum(:completed_at)&.in_time_zone
      return due_at if due_at.nil? || postponed_at.nil? || (last_completed_at && postponed_at < last_completed_at)

      [ due_at, postponed_at.to_date.next_day.in_time_zone ].max
    end
  end
end
