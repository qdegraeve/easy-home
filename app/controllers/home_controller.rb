class HomeController < ApplicationController
  def show
    @household = current_household
    return redirect_to(new_household_path) unless @household

    authorize @household
    plants = policy_scope(Plant).where(household: @household).order(:name)
    @plants = plants.active.includes(:location, watering_task: :pending_occurrence)
    @archived_plants = plants.archived
    @due_today = DueOccurrencesQuery.new(policy_scope(TaskOccurrence)).call(household_ids: @household.id)
      .includes(task: :subject).order(:due_at)
  end
end
