# "Tâches de la maison": the tasks of the house itself (bins…), attached to neither a plant nor an equipment, still to
# do, soonest first (a one-off task once done is gone, it stays in the journal). Each opens its sheet.
class HouseTasksController < ApplicationController
  def index
    @household = current_household
    return redirect_to(new_household_path) unless @household

    authorize @household, :update?
    @tasks = policy_scope(Task).where(household: @household).without_subject.to_do
      .includes(:pending_occurrence).order("task_occurrences.due_at", :id)
    @on_demand_tasks = policy_scope(Task).where(household: @household).without_subject.active.on_demand
      .order(:title).to_a
    @last_done_at = Task.last_done_at_by_id(@on_demand_tasks)
  end
end
