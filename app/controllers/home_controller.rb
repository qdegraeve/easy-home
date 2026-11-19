class HomeController < ApplicationController
  def show
    # Sans foyer, on autorise la classe : la policy refuse, ce qui donne une 403 plutôt qu'une 500.
    @household = Current.household
    authorize(@household || Household)
  end
end
