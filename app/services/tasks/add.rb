module Tasks
  # Adds a manual task with its first occurrence on the chosen date: to a subject (a plant…), or to the house itself
  # when there is none (bins…). The household is the subject's, or the given one for a house task.
  class Add
    include Dry::Monads[:result]

    def call(params:, subject: nil, household: nil)
      raise ArgumentError, "a subject or a household" unless subject || household

      form = TaskForm.new(params.to_h)
      return Failure[:subject_archived, form] if subject&.archived?
      return Failure[:invalid, form] unless form.valid?

      task = ActiveRecord::Base.transaction do
        task = Task.create!(household: subject&.household || household, subject:, **form.task_attributes)
        task.occurrences.create!(due_at: task.first_due_at(form.due_on))
        task
      end

      Success(task)
    end
  end
end
