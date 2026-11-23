module Recurrence
  # Fixed recurrence ("à jour fixe"): the dates of a rule, whatever happens. An anchor (the first date, "prochaine fois
  # le") and a step of N weeks (the bins, every other Tuesday: the weekday comes from the anchor) or N years (the
  # cyclone season every November 1st: the day of the year comes from the anchor; February 29 falls on the 28th the
  # other years). Done early, late or postponed, the next one is the first date of the rule after the last due date or
  # completion; a missed date is never caught up (see Tolerance.after_miss).
  class Fixed
    UNITS = { "weeks" => 1..52, "years" => 1..10 }.freeze

    attr_reader :anchor_on, :interval, :unit

    def initialize(anchor_on:, interval:, unit:)
      raise InvalidConfig, "anchor_on must be a Date, got #{anchor_on.inspect}" unless anchor_on.is_a?(Date)
      raise InvalidConfig, "unit must be one of #{UNITS.keys}, got #{unit.inspect}" unless UNITS.key?(unit.to_s)
      unless interval.is_a?(Integer) && UNITS.fetch(unit.to_s).cover?(interval)
        raise InvalidConfig, "interval must be an integer in #{UNITS.fetch(unit.to_s)}, got #{interval.inspect}"
      end

      @anchor_on = anchor_on
      @interval = interval
      @unit = unit.to_s
    end

    # The first date of the rule strictly after the last due date and the last completion (the one just closed), and
    # not before not_before. With neither, the first date not before not_before (the anchor when it is still ahead).
    def next_due_at(last_completed_at:, last_due_on: nil, not_before: nil)
      after = [ last_due_on, last_completed_at&.to_date ].compact.max
      floor = [ after&.next_day, not_before ].compact.max
      first_on_or_after(floor || anchor_on).in_time_zone
    end

    def period_days
      weeks? ? 7 * interval : 365 * interval
    end

    def dated?
      true
    end

    def weeks?
      unit == "weeks"
    end

    # The k-th date of the rule (k >= 0).
    def date_at(index)
      weeks? ? anchor_on + (7 * interval * index) : anchor_on >> (12 * interval * index)
    end

    private

    def first_on_or_after(day)
      return anchor_on if day <= anchor_on

      index = estimated_index(day)
      index += 1 while date_at(index) < day
      index -= 1 while index.positive? && date_at(index - 1) >= day
      date_at(index)
    end

    def estimated_index(day)
      steps = weeks? ? (day - anchor_on).to_i / (7 * interval) : (day.year - anchor_on.year) / interval
      [ steps, 0 ].max
    end
  end
end
