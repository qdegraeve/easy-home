# Time budget per spec, enforced in CI: a slow suite ends up not being run anymore.
# A spec over its budget fails with an explicit message. Make it faster (build
# instead of create, less navigation, minimal data) rather than raising the budget.
# See docs/tests.md.
module TimeBudget
  # Seconds per example.
  LIMITS = { system: 8.0, other: 1.0 }.freeze
  # Allowance for the first example of each kind (loading, Chrome startup).
  WARMUP = 10.0

  def self.kind(example)
    example.metadata[:type] == :system ? :system : :other
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
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      example.run

      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
      next if example.exception || elapsed <= limit

      raise "Spec too slow: #{elapsed.round(2)} s for a budget of #{limit} s (see docs/tests.md)"
    end
  end
end
