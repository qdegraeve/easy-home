class HomeController < ApplicationController
  # Temporary landing page without resource to authorize, replaced by the dashboard in step 1.
  skip_after_action :verify_pundit_authorization

  def show
  end
end
