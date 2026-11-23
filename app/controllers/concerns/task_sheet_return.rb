# Where "Fait" or "Reporter" leads. From a list, back to it (the toast says what happened). From the task sheet
# (`from: "sheet"`), a modal in the Android app: it is dismissed and the screen under it shows the toast; in a
# browser, the sheet again, now showing the task as done or postponed.
module TaskSheetReturn
  extend ActiveSupport::Concern

  private

  def redirect_after_occurrence_change(task, notice)
    if params[:from] == "sheet"
      flash[:notice] = notice
      recede_or_redirect_to task_path(task), status: :see_other
    else
      redirect_back_or_to root_path, notice:, status: :see_other
    end
  end
end
