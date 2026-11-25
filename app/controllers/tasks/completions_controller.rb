module Tasks
  # "Fait" on a task done when needed (Recurrence::OnDemand): recorded in the journal (Tasks::RecordDone). Back to the
  # list it was done from, or, from its sheet, as "Fait" does for a dated task (TaskSheetReturn).
  class CompletionsController < ApplicationController
    include TaskSheetReturn

    def create
      task = policy_scope(Task).find(params[:task_id]).tap { |record| authorize record, :record_done? }
      result = Tasks::RecordDone.new.call(task:, user: Current.user)

      notice = result.success? ? done_notice(task) : t(".#{result.failure.first}")
      flash[:undo_ids] = [ result.value!.id ] if result.success?
      redirect_after_occurrence_change(task, notice)
    end

    private

    def done_notice(task)
      return t("task_occurrences.completions.create.success_without_subject", title: task.title) unless task.subject

      t("task_occurrences.completions.create.success", title: task.title, subject: task.subject.name)
    end
  end
end
