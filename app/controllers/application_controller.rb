class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  after_action :verify_pundit_authorization

  private

  def verify_pundit_authorization
    action_name == "index" ? verify_policy_scoped : verify_authorized
  end
end
