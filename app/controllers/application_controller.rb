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

  def forbidden
    head :forbidden
  end
end
