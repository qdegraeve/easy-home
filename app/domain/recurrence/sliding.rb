module Recurrence
  # Sliding recurrence: the next occurrence falls interval_days days after the last completion, at the start of the
  # day, in the time zone of that completion. Never done: start_on when set, otherwise interval_days days from
  # today.
  class Sliding
    INTERVAL_DAYS = 1..60

    attr_reader :interval_days, :start_on

    def initialize(interval_days:, start_on: nil)
      unless interval_days.is_a?(Integer) && INTERVAL_DAYS.cover?(interval_days)
        raise InvalidConfig, "interval_days must be an integer in #{INTERVAL_DAYS}, got #{interval_days.inspect}"
      end
      unless start_on.nil? || start_on.is_a?(Date)
        raise InvalidConfig, "start_on must be a Date, got #{start_on.inspect}"
      end

      @interval_days = interval_days
      @start_on = start_on
    end

    def next_due_at(last_completed_at:)
      return (start_on || Time.zone.today + interval_days).in_time_zone if last_completed_at.nil?

      (last_completed_at.to_date + interval_days).in_time_zone(last_completed_at.time_zone)
    end

    # Missed, it is still to do (the plant still needs water).
    def closed_by_miss?
      false
    end
  end
end
