module Recurrence
  # Récurrence glissante : la prochaine échéance tombe interval_days jours après la dernière réalisation, au début de
  # la journée, dans le fuseau de cette réalisation.
  class Sliding
    INTERVAL_DAYS = 1..60

    attr_reader :interval_days

    def initialize(interval_days:)
      unless interval_days.is_a?(Integer) && INTERVAL_DAYS.cover?(interval_days)
        raise InvalidConfig, "interval_days must be an integer in #{INTERVAL_DAYS}, got #{interval_days.inspect}"
      end

      @interval_days = interval_days
    end

    # last_completed_at : ActiveSupport::TimeWithZone. Renvoie un TimeWithZone dans le même fuseau.
    def next_due_at(last_completed_at:)
      (last_completed_at.to_date + interval_days).in_time_zone(last_completed_at.time_zone)
    end
  end
end
