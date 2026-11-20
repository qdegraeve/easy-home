require "rails_helper"

RSpec.describe "Configurations", type: :request do
  it "serves the Android path configuration without authentication" do
    get android_v1_configuration_path

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("application/json")
    rules = response.parsed_body["rules"].to_h { |rule| [ rule["patterns"], rule["properties"] ] }
    expect(rules[[ ".*" ]]).to include("context" => "default", "uri" => "hotwire://fragment/web")
    expect(rules[[ "/new$", "/edit$" ]]).to include("context" => "modal", "pull_to_refresh_enabled" => false)
  end

  # The last matching rule wins: the sign-in page ends with /new but must never open as a modal (the app froze after
  # signing in), and the home page clears the stack so that "back" never returns to the sign-in page.
  it "opens the sign-in pages and the home page in place of the whole stack, after the modal rule" do
    get android_v1_configuration_path

    patterns, properties = response.parsed_body["rules"].last.values_at("patterns", "properties")
    expect(patterns).to eq([ "^/$", "/session/new$", "/passwords/new$" ])
    expect(properties).to include("context" => "default", "presentation" => "replace_root")
  end

  it "matches the copy bundled in the Android app, used when the server cannot be reached" do
    bundled = Rails.root.join("android/app/src/main/assets/json/path-configuration.json")

    expect(JSON.parse(bundled.read)).to eq(JSON.parse(Rails.root.join("config/hotwire/android_v1.json").read))
  end
end
