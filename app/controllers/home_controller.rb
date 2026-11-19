class HomeController < ApplicationController
  def show
    @household = Current.household
    authorize @household
  end
end
