# "Maison": the inventory of the household, by domain (plants for now; bins, pool, pets, equipment to come), and the
# places of the house (UX review).
class HouseController < ApplicationController
  def show
    @household = current_household
    return redirect_to(new_household_path) unless @household

    authorize @household
    plants = policy_scope(Plant).where(household: @household).active.includes(:location, :analyses).to_a
    @plants_count = plants.size
    @analyses_to_review = plants.count(&:place_change_since_analysis)
    @locations_count = @household.locations.count
  end
end
