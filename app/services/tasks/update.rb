module Tasks
  # Updates a manual task: title, rhythm (its type too: one-off, every N days, fixed dates), importance, instructions,
  # and the next occurrence date as typed ("Prochaine fois le"). When that date is the one already open, it is left
  # as is: a title or an instruction changed never moves the task (nor, on fixed dates, its weekday after a
  # postponement, nor a flexible task reopened after a miss). Changed:
  # - every N days: a task already done keeps its start date (cancelling all its completions brings it back to its
  #   original date); never done, the typed date becomes its start date;
  # - fixed dates: the typed date becomes the anchor, the whole series moves.
  # A repeating task without an open occurrence (a one-off just turned into a repeating one) gets one.
  class Update
    include Dry::Monads[:result]

    def call(task:, params:)
      # From the task as it is, the params on top: what is not given is kept (the rhythm, its interval…).
      form = TaskForm.from(task)
      form.assign_attributes(params.to_h.with_indifferent_access.except(:suggestion_key))
      return Failure[:invalid, form] unless form.valid?

      ActiveRecord::Base.transaction do
        task.lock!
        pending = task.occurrences.pending.first
        date_kept = pending && pending.due_at.to_date == form.due_on && task.recurrence_type == form.recurrence_type
        task.update!(changes_for(task, form, date_kept))
        move_open_occurrence(task, pending, form.due_on) unless date_kept
        restart_reminders(pending) if pending && task.saved_change_to_reminder_minute?
      end

      Success(task)
    end

    private

    def changes_for(task, form, date_kept)
      changes = form.task_attributes.except(:suggestion_key)
      config = changes[:recurrence_config]
      if task.sliding? && form.sliding? && (date_kept || task.occurrences.done.exists?)
        config["start_on"] = task.recurrence_config["start_on"]
      elsif task.fixed? && form.fixed? && date_kept
        config["anchor_on"] = task.recurrence_config["anchor_on"]
      end
      changes
    end

    # A new reminder time is a new reminder: sent at that time, even when the former one was already sent today.
    def restart_reminders(pending)
      pending.update!(reminders_sent: 0, last_reminded_at: nil)
    end

    # A new due date can be missed again, once (Tasks::MarkMissed); its reminders start again (RemindersDueQuery
    # counts those of the due day only).
    def move_open_occurrence(task, pending, due_on)
      if pending
        pending.update!(due_at: task.first_due_at!(due_on), reopened_after_miss: false)
      elsif task.active? && !task.once?
        task.occurrences.create!(due_at: task.first_due_at!(due_on))
      end
    end
  end
end
