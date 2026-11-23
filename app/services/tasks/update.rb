module Tasks
  # Updates a manual task: title, rhythm (its type too: one-off, every N days, fixed dates), importance, instructions,
  # and the next occurrence date as typed ("Prochaine fois le"). A sliding task already done keeps its start date
  # (cancelling all its completions brings it back to its original date); never done, the typed date becomes its
  # start date. On fixed dates, the typed date becomes the anchor: the whole series moves. A repeating task without an
  # open occurrence (a one-off just turned into a repeating one) gets one.
  class Update
    include Dry::Monads[:result]

    def call(task:, params:)
      attributes = params.to_h.with_indifferent_access.except(:suggestion_key)
      attributes[:recurrence_type] ||= task.recurrence_type # the rhythm is kept unless chosen again
      form = TaskForm.new(attributes)
      return Failure[:invalid, form] unless form.valid?

      ActiveRecord::Base.transaction do
        task.lock!
        same_rhythm = task.recurrence_type == form.recurrence_type
        attributes = form.task_attributes.except(:suggestion_key)
        if same_rhythm && task.sliding? && task.occurrences.done.exists?
          attributes[:recurrence_config]["start_on"] = task.recurrence_config["start_on"]
        end
        task.update!(attributes)
        move_open_occurrence(task, form.due_on)
      end

      Success(task)
    end

    private

    # A new due date can be missed again, once (Tasks::MarkMissed).
    def move_open_occurrence(task, due_on)
      pending = task.occurrences.pending.first
      if pending
        pending.update!(due_at: task.first_due_at(due_on), reopened_after_miss: false)
      elsif task.active? && !task.once?
        task.occurrences.create!(due_at: task.first_due_at(due_on))
      end
    end
  end
end
