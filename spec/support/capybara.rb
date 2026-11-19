require "capybara/rspec"
require "capybara/cuprite"

Capybara.default_max_wait_time = 3
Capybara.disable_animation = true
Capybara.enable_aria_label = true

RSpec.configure do |config|
  config.before(:each, type: :system) do
    # Options go through driven_by: Rails registers the :cuprite driver again on each call
    # and would ignore a Capybara.register_driver(:cuprite) defined separately.
    driven_by(
      :cuprite,
      screen_size: [ 390, 844 ], # mobile first: the app runs in an Android webview
      options: {
        js_errors: true, # a JS error fails the spec
        process_timeout: 15,
        timeout: 10,
        # Chromium runs as root in containers (Docker dev, CI): sandbox disabled.
        browser_options: { "no-sandbox" => nil }
      }
    )
  end
end
