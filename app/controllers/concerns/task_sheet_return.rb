# Where "Fait", "Reporter" or a deletion leads. From a list, back to it (the toast says what happened). From the task
# sheet (`from: "sheet"`), a modal in the Android app: it is dismissed and the screen under it shows the toast; in a
# browser, the sheet again, now showing the task as done or postponed (or, deleted, the page it belonged to).
# `resume` only dismisses the modal; `recede` would then also leave the screen under it (docs/android-coque.md).
module TaskSheetReturn
  extend ActiveSupport::Concern

  private

  def redirect_after_occurrence_change(task, notice)
    if from_task_sheet?
      close_task_sheet(task_path(task), notice)
    else
      redirect_back_or_to root_path, notice:, status: :see_other
    end
  end

  def from_task_sheet?
    params[:from] == "sheet"
  end

  def close_task_sheet(browser_path, notice)
    flash[:notice] = notice
    resume_or_redirect_to browser_path, status: :see_other
  end
end
