module Tasks
  # Updates a manual task: title, interval, and the next occurrence date as typed. The repetition type never
  # changes. A repeating task already done keeps its start date (cancelling all its completions brings it back to
  # its original date); never done, the typed date becomes its start date.
  class Update
    include Dry::Monads[:result]

    def call(task:, params:)
      form = TaskForm.new(params.to_h.merge(recurrence_type: task.recurrence_type))
      return Failure[:invalid, form] unless form.valid?

      ActiveRecord::Base.transaction do
        task.lock!
        attributes = form.task_attributes
        if task.sliding? && task.occurrences.done.exists?
          attributes[:recurrence_config]["start_on"] = task.recurrence_config["start_on"]
        end
        task.update!(attributes)
        task.occurrences.pending.first&.update!(due_at: form.due_on.in_time_zone)
      end

      Success(task)
    end
  end
end
