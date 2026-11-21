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

  def edit
    @location = find_location
  end

  # A change of exposure or shelter makes the analyses of its plants to review (Plant#place_change_since_analysis).
  def update
    @location = find_location

    if @location.update(location_params)
      redirect_to edit_household_path(@location.household), notice: t(".success", name: @location.name)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    location = find_location

    location.destroy!
    redirect_to edit_household_path(location.household), notice: t(".success", name: location.name)
  end

  private

  def find_location
    Location.where(household: policy_scope(Household)).find(params[:id]).tap { |location| authorize location }
  end

  def location_params
    params.expect(location: [ :name, :exposure, :sheltered ])
  end
end
