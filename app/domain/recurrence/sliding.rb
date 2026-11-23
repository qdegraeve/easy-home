module Recurrence
  # Sliding recurrence ("après la dernière fois"): the next occurrence falls one period after the last completion, at
  # the start of the day, in the time zone of that completion. A period is N days (a plant watered every 3 days), weeks,
  # months (the dishwasher filter every month; the 31st falls on the last day of a shorter month) or years (the anode
  # every 2 years). Never done: start_on when set, otherwise one period from today.
  class Sliding
    UNITS = { "days" => 1..60, "weeks" => 1..52, "months" => 1..24, "years" => 1..10 }.freeze
    # Days of a period, for the tolerance (a quarter of it, Tolerance).
    UNIT_DAYS = { "days" => 1, "weeks" => 7, "months" => 30, "years" => 365 }.freeze

    attr_reader :interval, :unit, :start_on

    def initialize(interval:, unit: "days", start_on: nil)
      raise InvalidConfig, "unit must be one of #{UNITS.keys}, got #{unit.inspect}" unless UNITS.key?(unit.to_s)
      unless interval.is_a?(Integer) && UNITS.fetch(unit.to_s).cover?(interval)
        raise InvalidConfig, "interval must be an integer in #{UNITS.fetch(unit.to_s)}, got #{interval.inspect}"
      end
      unless start_on.nil? || start_on.is_a?(Date)
        raise InvalidConfig, "start_on must be a Date, got #{start_on.inspect}"
      end

      @interval = interval
      @unit = unit.to_s
      @start_on = start_on
    end

    def next_due_at(last_completed_at:, last_due_on: nil, not_before: nil) # rubocop:disable Lint/UnusedMethodArgument
      return (start_on || after_period(Time.zone.today)).in_time_zone if last_completed_at.nil?

      after_period(last_completed_at.to_date).in_time_zone(last_completed_at.time_zone)
    end

    # The interval in days, for the rules counted in days (the watering of a plant), nil otherwise.
    def interval_days
      interval if unit == "days"
    end

    def period_days
      UNIT_DAYS.fetch(unit) * interval
    end

    def dated?
      true
    end

    private

    def after_period(date)
      case unit
      when "days" then date + interval
      when "weeks" then date + (7 * interval)
      when "months" then date >> interval
      else date >> (12 * interval)
      end
    end
  end
end
