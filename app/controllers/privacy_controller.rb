# "Confidentialité": public page required by the app stores (ADR 0019). The text lives in the locale file.
class PrivacyController < ApplicationController
  allow_unauthenticated_access

  def show
  end
end
