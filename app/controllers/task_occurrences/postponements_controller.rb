module TaskOccurrences
  # "Reporter" on a task of the day: postponed to tomorrow (Tasks::Postpone), undone from the toast.
  class PostponementsController < ApplicationController
    include TaskSheetReturn

    def create
      occurrence = find_occurrence
      result = Tasks::Postpone.new.call(occurrence:, user: Current.user)

      notice = if result.success?
        postponed, = result.value!
        flash[:undo_postponement_id] = postponed.id
        postponed_notice(occurrence.task)
      else
        t(".#{result.failure.first}")
      end
      redirect_after_occurrence_change(occurrence.task, notice)
    end

    def destroy
      result = Tasks::CancelPostponement.new.call(occurrence: find_occurrence)

      notice = result.success? ? t(".success") : t(".#{result.failure.first}")
      redirect_back_or_to root_path, notice:, status: :see_other
    end

    private

    # "Reporté à demain : Tailler (Citronnier)." or, for a task without subject, "Reporté à demain : Poubelle jaune.".
    def postponed_notice(task)
      return t(".success_without_subject", title: task.title) unless task.subject

      t(".success", title: task.title, subject: task.subject.name)
    end

    def find_occurrence
      occurrence = policy_scope(TaskOccurrence).find(params[:task_occurrence_id])
      authorize occurrence, :postpone?
      occurrence
    end
  end
end
