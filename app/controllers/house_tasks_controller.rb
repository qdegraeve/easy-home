# "Tâches de la maison": the tasks of the house itself (bins…), attached to neither a plant nor an equipment, with
# their next due date, soonest first; a one-off task already done is gone (it stays in the journal). Each opens its
# sheet.
class HouseTasksController < ApplicationController
  def index
    @household = current_household
    return redirect_to(new_household_path) unless @household

    authorize Task.new(household: @household), :show?
    @tasks = policy_scope(Task).where(household: @household).without_subject.active
      .includes(:pending_occurrence).select(&:pending_occurrence)
      .sort_by { |task| [ task.pending_occurrence.due_at, task.id ] }
  end
end
