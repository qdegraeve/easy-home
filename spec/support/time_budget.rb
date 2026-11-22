# Time budget per spec, enforced in CI: a slow suite ends up not being run anymore.
# A spec over its budget fails with an explicit message. Make it faster (build
# instead of create, less navigation, minimal data) rather than raising the budget.
# See docs/tests.md.
module TimeBudget
  # Seconds per example.
  LIMITS = { system: 8.0, other: 1.0 }.freeze
  # Allowance for the first example of each kind (loading the app, first page compiled).
  WARMUP = 10.0

  class << self
    # Seconds spent starting Chrome in the current example: not the spec's fault, and from 2 to 20 s on a CI runner,
    # so it is left out of the budget.
    attr_accessor :browser_boot

    def kind(example)
      example.metadata[:type] == :system ? :system : :other
    end
  end
end

if ENV["CI"]
  RSpec.configure do |config|
    warmed_up = {}

    config.around(:each) do |example|
      kind = TimeBudget.kind(example)
      limit = TimeBudget::LIMITS.fetch(kind)
      limit += TimeBudget::WARMUP unless warmed_up[kind]
      warmed_up[kind] = true
      TimeBudget.browser_boot = 0.0
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      example.run

      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at - TimeBudget.browser_boot
      next if example.exception || elapsed <= limit

      raise "Spec too slow: #{elapsed.round(2)} s for a budget of #{limit} s (see docs/tests.md)"
    end

    # Runs after driven_by (spec/support/capybara.rb is loaded first): starts Chrome if it is not running yet, and
    # times it.
    config.before(:each, type: :system) do
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      page.driver.browser
      TimeBudget.browser_boot = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
    end
  end
end
