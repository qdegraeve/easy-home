require "webmock/rspec"

# Aucun appel réseau dans la suite (docs/tests.md). localhost reste ouvert pour Capybara et Chrome.
WebMock.disable_net_connect!(allow_localhost: true)
