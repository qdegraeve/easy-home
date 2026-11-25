module Recurrence
  # A single occurrence on due_on (at the start of the local day). Once done, there is none left.
  class Once
    attr_reader :due_on

    def initialize(due_on:)
      raise InvalidConfig, "due_on must be a Date, got #{due_on.inspect}" unless due_on.is_a?(Date)

      @due_on = due_on
    end

    def next_due_at(last_completed_at:, last_due_on: nil, not_before: nil) # rubocop:disable Lint/UnusedMethodArgument
      due_on.in_time_zone if last_completed_at.nil?
    end

    def period_days
      nil
    end

    def dated?
      true
    end
  end
end
