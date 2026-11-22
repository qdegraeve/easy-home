module TaskOccurrences
  # "Demain" on a task of the day: postponed to tomorrow (Tasks::Postpone).
  class PostponementsController < ApplicationController
    def create
      occurrence = policy_scope(TaskOccurrence).find(params[:task_occurrence_id])
      authorize occurrence, :postpone?
      result = Tasks::Postpone.new.call(occurrence:, user: Current.user)

      notice = if result.success?
        t(".success", title: occurrence.task.title, subject: occurrence.task.subject&.name)
      else
        t(".#{result.failure.first}")
      end
      redirect_back_or_to root_path, notice:, status: :see_other
    end
  end
end
