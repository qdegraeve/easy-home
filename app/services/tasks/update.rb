module Tasks
  # Modifie une tâche manuelle : titre, intervalle, et date de la prochaine échéance telle que saisie. Le type de
  # répétition ne change pas. Une tâche répétée déjà faite garde sa date de début (annuler toutes ses réalisations
  # la ramène à sa date d'origine) ; jamais faite, la date saisie devient sa date de début.
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
