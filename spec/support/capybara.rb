require "capybara/rspec"
require "capybara/cuprite"

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [ 390, 844 ], # mobile d'abord : l'app tourne dans une webview Android
    js_errors: true,           # une erreur JS fait échouer la spec
    process_timeout: 15,
    timeout: 10,
    # Chromium tourne en root dans les conteneurs (dev Docker, CI) : bac à sable désactivé.
    browser_options: { "no-sandbox" => nil }
  )
end

Capybara.default_driver = :cuprite
Capybara.javascript_driver = :cuprite
Capybara.default_max_wait_time = 3
Capybara.disable_animation = true

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :cuprite
  end
end
