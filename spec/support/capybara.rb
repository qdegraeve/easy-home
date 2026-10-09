require "capybara/rspec"
require "capybara/cuprite"

Capybara.default_max_wait_time = 3
Capybara.disable_animation = true

RSpec.configure do |config|
  config.before(:each, type: :system) do
    # Les options passent par driven_by : Rails réenregistre le driver :cuprite à chaque appel
    # et ignorerait un Capybara.register_driver(:cuprite) défini à part.
    driven_by(
      :cuprite,
      screen_size: [ 390, 844 ], # mobile d'abord : l'app tourne dans une webview Android
      options: {
        js_errors: true, # une erreur JS fait échouer la spec
        process_timeout: 15,
        timeout: 10,
        # Chromium tourne en root dans les conteneurs (dev Docker, CI) : bac à sable désactivé.
        browser_options: { "no-sandbox" => nil }
      }
    )
  end
end
