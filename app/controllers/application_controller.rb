class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  rescue_from Pundit::NotAuthorizedError, with: :forbidden

  private

  def pundit_user
    Current.user
  end

  # Current household stored in the session; otherwise the user's first household. nil when they have none.
  def current_household
    households = policy_scope(Household)
    households.find_by(id: session[:household_id]) || households.order(:name, :id).first
  end

  def forbidden
    head :forbidden
  end
end
