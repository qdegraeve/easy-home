module TaskOccurrences
  class CompletionsController < ApplicationController
    def create
      occurrence = policy_scope(TaskOccurrence).find(params[:task_occurrence_id])
      authorize occurrence, :complete?

      result = Tasks::Complete.new.call(occurrence:, user: Current.user)
      # Déjà faite (double appui, autre membre) : même retour, l'état affiché est à jour.
      notice = result.success? ? t(".success", title: occurrence.task.title, subject: occurrence.task.subject&.name) : t(".already_done")
      redirect_back_or_to root_path, notice:, status: :see_other
    end
  end
end
