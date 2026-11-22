module TaskOccurrences
  # "Demain" on a task of the day: postponed to tomorrow (Tasks::Postpone), undone from the toast.
  class PostponementsController < ApplicationController
    def create
      occurrence = find_occurrence
      result = Tasks::Postpone.new.call(occurrence:, user: Current.user)

      notice = if result.success?
        postponed, = result.value!
        flash[:undo_postponement_id] = postponed.id
        t(".success", title: occurrence.task.title, subject: occurrence.task.subject&.name)
      else
        t(".#{result.failure.first}")
      end
      redirect_back_or_to root_path, notice:, status: :see_other
    end

    def destroy
      result = Tasks::CancelPostponement.new.call(occurrence: find_occurrence)

      notice = result.success? ? t(".success") : t(".#{result.failure.first}")
      redirect_back_or_to root_path, notice:, status: :see_other
    end

    private

    def find_occurrence
      occurrence = policy_scope(TaskOccurrence).find(params[:task_occurrence_id])
      authorize occurrence, :postpone?
      occurrence
    end
  end
end
