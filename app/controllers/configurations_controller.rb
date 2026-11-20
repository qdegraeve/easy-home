# Navigation rules of the Android app (Hotwire Native path configuration), served so they change without a new
# release of the app. The app bundles a copy as a fallback (android/app/src/main/assets/json/); a spec keeps both
# identical. The version in the path never changes meaning: a breaking change gets a new version, so older installed
# apps keep working.
class ConfigurationsController < ApplicationController
  allow_unauthenticated_access

  ANDROID_V1 = Rails.root.join("config/hotwire/android_v1.json").read.freeze

  def android_v1
    render json: ANDROID_V1
  end
end
