# "Maison": the inventory of the household, by domain (plants, the tasks of the house itself; equipment to come), and
# the places of the house (UX review). "new" is the "+" of Maison: what to add.
class HouseController < ApplicationController
  def show
    @household = current_household
    return redirect_to(new_household_path) unless @household

    authorize @household
    plants = policy_scope(Plant).where(household: @household).active.includes(:location, :analyses).to_a
    @plants_count = plants.size
    # Analyses are not a guest's (ADR 0019).
    @analyses_to_review = policy(@household).manage? ? plants.count(&:place_change_since_analysis) : 0
    @locations_count = @household.locations.count
    @equipment_count = policy_scope(Equipment).where(household: @household).count
    house_tasks = policy_scope(Task).where(household: @household).without_subject
    @house_tasks_count = house_tasks.to_do.count + house_tasks.active.on_demand.count
  end

  def new
    @household = current_household
    return redirect_to(new_household_path) unless @household

    authorize @household, :manage?
  end
end
