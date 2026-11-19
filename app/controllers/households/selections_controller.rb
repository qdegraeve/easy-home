module Households
  class SelectionsController < ApplicationController
    def create
      household = policy_scope(Household).find(params[:household_id])
      authorize household, :show?

      session[:household_id] = household.id
      redirect_to root_path
    end
  end
end
