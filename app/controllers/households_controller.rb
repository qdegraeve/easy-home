class HouseholdsController < ApplicationController
  def index
    @households = policy_scope(Household).order(:name, :id)
    @current_household = current_household
  end

  def new
    @household = Household.new
    authorize @household
  end

  def create
    authorize Household

    case Households::Create.new.call(user: Current.user, params: household_params)
    in Success(household)
      session[:household_id] = household.id
      redirect_to root_path, notice: t(".success", name: household.name)
    in Failure[ :invalid, household ]
      @household = household
      render :new, status: :unprocessable_content
    end
  end

  private

  def household_params = params.expect(household: [ :name ])
end
