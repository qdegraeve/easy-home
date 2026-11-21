# "Maison": the inventory of the household, by domain (plants for now; bins, pool, pets, equipment to come), and the
# places of the house (UX review).
class HouseController < ApplicationController
  def show
    @household = current_household
    return redirect_to(new_household_path) unless @household

    authorize @household
    @plants_count = policy_scope(Plant).where(household: @household).active.count
    @locations_count = @household.locations.count
  end
end
