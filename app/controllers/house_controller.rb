# "Maison": the inventory of the household, by domain (plants, the tasks of the house itself; equipment to come), and
# the places of the house (UX review). "new" is the "+" of Maison: what to add.
class HouseController < ApplicationController
  def show
    @household = current_household
    return redirect_to(new_household_path) unless @household

    authorize @household
    plants = policy_scope(Plant).where(household: @household).active.includes(:location, :analyses).to_a
    @plants_count = plants.size
    @analyses_to_review = plants.count(&:place_change_since_analysis)
    @locations_count = @household.locations.count
    @house_tasks_count = policy_scope(Task).where(household: @household).without_subject.to_do.count
  end

  def new
    @household = current_household
    return redirect_to(new_household_path) unless @household

    authorize @household, :update?
  end
end
