class LocationsController < ApplicationController
  def create
    @household = policy_scope(Household).find(params[:household_id])
    @location = Location.new(location_params.merge(household: @household))
    authorize @location

    if @location.save
      redirect_to edit_household_path(@household), notice: t(".success", name: @location.name)
    else
      render "households/edit", status: :unprocessable_content
    end
  end

  def destroy
    location = Location.where(household: policy_scope(Household)).find(params[:id])
    authorize location

    location.destroy!
    redirect_to edit_household_path(location.household), notice: t(".success", name: location.name)
  end

  private

  def location_params
    params.expect(location: [ :name, :exposure, :sheltered ])
  end
end
