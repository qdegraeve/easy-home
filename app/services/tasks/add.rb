module Tasks
  # Adds a manual task to a subject (a plant…) with its first occurrence on the chosen date.
  class Add
    include Dry::Monads[:result]

    def call(subject:, params:)
      form = TaskForm.new(params.to_h)
      return Failure[:subject_archived, form] if subject.archived?
      return Failure[:invalid, form] unless form.valid?

      task = ActiveRecord::Base.transaction do
        task = subject.tasks.create!(household: subject.household, **form.task_attributes)
        task.occurrences.create!(due_at: form.due_on.in_time_zone)
        task
      end

      Success(task)
    end
  end
end
