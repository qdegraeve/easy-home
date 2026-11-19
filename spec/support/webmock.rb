require "webmock/rspec"

# No network call in the suite (docs/tests.md). localhost stays open for Capybara and Chrome.
WebMock.disable_net_connect!(allow_localhost: true)
