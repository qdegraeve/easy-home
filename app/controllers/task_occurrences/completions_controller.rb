module TaskOccurrences
  class CompletionsController < ApplicationController
    def create
      occurrence = find_occurrence
      result = Tasks::Complete.new.call(occurrence:, user: Current.user)

      notice = if result.success?
        flash[:undo_ids] = [ result.value!.id ] # the occurrence done, maybe the reopened one (Tasks::Complete)
        done_notice(occurrence.task)
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

    # "Tailler noté pour « Citronnier ».", or "Sortir la poubelle jaune noté." for a task of the house.
    def done_notice(task)
      return t(".success_without_subject", title: task.title) unless task.subject

      t(".success", title: task.title, subject: task.subject.name)
    end

    def find_occurrence
      occurrence = policy_scope(TaskOccurrence).find(params[:task_occurrence_id])
      authorize occurrence, :complete?
      occurrence
    end
  end
end
