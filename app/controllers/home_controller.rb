class HomeController < ApplicationController
  def show
    @household = current_household
    return redirect_to(new_household_path) unless @household

    authorize @household
    plants = policy_scope(Plant).where(household: @household).order(:name)
    @plants = plants.active.includes(:location, watering_task: :pending_occurrence)
    @archived_plants = plants.archived
    @due_today = policy_scope(TaskOccurrence).pending
      .where(tasks: { household_id: @household.id, active: true })
      .where(due_at: ..Time.zone.today.end_of_day)
      .includes(task: :subject).order(:due_at)
  end
end
