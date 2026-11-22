module Recurrence
  # A single occurrence on due_on (at the start of the local day). Once done, there is none left.
  class Once
    attr_reader :due_on

    def initialize(due_on:)
      raise InvalidConfig, "due_on must be a Date, got #{due_on.inspect}" unless due_on.is_a?(Date)

      @due_on = due_on
    end

    def next_due_at(last_completed_at:)
      due_on.in_time_zone if last_completed_at.nil?
    end

    # Missed (a one-off task that must not be missed): its day has passed, it is over, like once done.
    def closed_by_miss?
      true
    end
  end
end
