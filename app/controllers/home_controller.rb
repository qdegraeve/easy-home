class HomeController < ApplicationController
  def show
    @household = current_household
    return redirect_to(new_household_path) unless @household

    authorize @household
    plants = policy_scope(Plant).where(household: @household).order(:name)
    @plants = plants.active.includes(:location, watering_task: :pending_occurrence)
    @to_water = @plants.select(&:needs_watering?)
    @archived_plants = plants.archived
  end
end
