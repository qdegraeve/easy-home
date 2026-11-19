module Tasks
  # Modifie une tâche manuelle : titre, intervalle, et date de la prochaine échéance telle que saisie. Le type de
  # répétition ne change pas.
  class Update
    include Dry::Monads[:result]

    def call(task:, params:)
      form = TaskForm.new(params.to_h.merge(recurrence_type: task.recurrence_type))
      return Failure[:invalid, form] unless form.valid?

      ActiveRecord::Base.transaction do
        task.lock!
        task.update!(form.task_attributes)
        task.occurrences.pending.first&.update!(due_at: form.due_on.in_time_zone)
      end

      Success(task)
    end
  end
end
