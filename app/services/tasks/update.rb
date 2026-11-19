module Tasks
  # Modifie une tâche manuelle : titre, intervalle, et date de la prochaine échéance telle que saisie. Le type de
  # répétition et la date de début d'une tâche répétée ne changent pas : annuler toutes ses réalisations la ramène à
  # sa date d'origine.
  class Update
    include Dry::Monads[:result]

    def call(task:, params:)
      form = TaskForm.new(params.to_h.merge(recurrence_type: task.recurrence_type))
      return Failure[:invalid, form] unless form.valid?

      ActiveRecord::Base.transaction do
        task.lock!
        attributes = form.task_attributes
        attributes[:recurrence_config]["start_on"] = task.recurrence_config["start_on"] if task.sliding?
        task.update!(attributes)
        task.occurrences.pending.first&.update!(due_at: form.due_on.in_time_zone)
      end

      Success(task)
    end
  end
end
