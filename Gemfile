source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.4"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.7"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Bundle and transpile JavaScript [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Bundle and process CSS [https://github.com/rails/cssbundling-rails]
gem "cssbundling-rails"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "kamal", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# Result monad for services (Success/Failure) [https://github.com/dry-rb/dry-monads]
gem "dry-monads", "~> 1.11"

# Reusable, testable & encapsulated view components [https://github.com/ViewComponent/view_component]
gem "view_component", "~> 4.15"

# Minimal authorization through OO design and pure Ruby classes [https://github.com/varvet/pundit]
gem "pundit", "~> 2.5"

# Recurring date library for the recurrence engine [https://github.com/ice-cube-ruby/ice_cube]
gem "ice_cube", "~> 0.17"

# Locale data for Rails (fr) [https://github.com/svenfuchs/rails-i18n]
gem "rails-i18n", "~> 8.1"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # Test framework [https://github.com/rspec/rspec-rails]
  gem "rspec-rails", "~> 8.0"

  # Factories as a replacement for fixtures [https://github.com/thoughtbot/factory_bot_rails]
  gem "factory_bot_rails", "~> 6.5"

  # One-liners to test common Rails functionality [https://github.com/thoughtbot/shoulda-matchers]
  gem "shoulda-matchers", "~> 8.0"

  # RSpec matchers for testing Pundit authorisation policies [https://github.com/pundit-community/pundit-matchers]
  gem "pundit-matchers", "~> 4.0"
end

group :test do
  # Acceptance test framework for web applications [https://github.com/teamcapybara/capybara]
  gem "capybara", "~> 3.40"

  # Headless Chrome driver for Capybara, using the Chrome DevTools Protocol [https://github.com/rubycdp/cuprite]
  gem "cuprite", "~> 0.18"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end
