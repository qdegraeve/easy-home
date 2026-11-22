module TaskOccurrences
  class CompletionsController < ApplicationController
    def create
      occurrence = find_occurrence
      result = Tasks::Complete.new.call(occurrence:, user: Current.user)

      notice = if result.success?
        flash[:undo_ids] = [ result.value!.id ] # the occurrence done, maybe the reopened one (Tasks::Complete)
        t(".success", title: occurrence.task.title, subject: occurrence.task.subject&.name)
      else
        t(".#{result.failure.first}")
      end
      redirect_back_or_to root_path, notice:, status: :see_other
    end

    def destroy
      occurrence = find_occurrence
      result = Tasks::CancelCompletion.new.call(occurrence:)

      notice = if result.failure?
        t(".not_done")
      else
        # Stopped task (archived plant): the completion leaves the log, no new occurrence is scheduled.
        t(occurrence.task.active? ? ".success" : ".success_stopped", title: occurrence.task.title)
      end
      redirect_back_or_to root_path, notice:, status: :see_other
    end

    private

    def find_occurrence
      occurrence = policy_scope(TaskOccurrence).find(params[:task_occurrence_id])
      authorize occurrence, :complete?
      occurrence
    end
  end
end
