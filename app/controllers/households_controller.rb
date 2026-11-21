class HouseholdsController < ApplicationController
  def index
    @households = policy_scope(Household).order(:name, :id)
    @roles = Current.user.household_members.pluck(:household_id, :role).to_h
    @current_household = current_household
  end

  def new
    @household = Household.new
    authorize @household
  end

  def create
    authorize Household

    result = Households::Create.new.call(user: Current.user, params: household_params)

    if result.success?
      household = result.value!
      session[:household_id] = household.id
      redirect_to root_path, notice: t(".success", name: household.name)
    else
      _code, @household = result.failure
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @household = policy_scope(Household).find(params[:id])
    authorize @household
    @location = Location.new(household: @household)
  end

  def update
    @household = policy_scope(Household).find(params[:id])
    authorize @household

    result = Households::UpdateAddress.new.call(household: @household, params: address_params)

    if result.success?
      redirect_to edit_household_path(@household), notice: t(".success")
    else
      @location = Location.new(household: @household)
      render :edit, status: :unprocessable_content
    end
  end

  private

  def household_params
    params.expect(household: [ :name ])
  end

  def address_params
    params.expect(household: [ :address, :latitude, :longitude, :altitude_m ])
  end
end
