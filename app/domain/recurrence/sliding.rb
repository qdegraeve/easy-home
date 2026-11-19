module Recurrence
  # Récurrence glissante : la prochaine échéance tombe interval_days jours après la dernière réalisation, au début de
  # la journée, dans le fuseau de cette réalisation. Jamais faite : start_on s'il est fixé, sinon dans interval_days
  # jours à partir d'aujourd'hui.
  class Sliding
    INTERVAL_DAYS = 1..60

    attr_reader :interval_days, :start_on

    def initialize(interval_days:, start_on: nil)
      unless interval_days.is_a?(Integer) && INTERVAL_DAYS.cover?(interval_days)
        raise InvalidConfig, "interval_days must be an integer in #{INTERVAL_DAYS}, got #{interval_days.inspect}"
      end
      raise InvalidConfig, "start_on must be a Date, got #{start_on.inspect}" unless start_on.nil? || start_on.is_a?(Date)

      @interval_days = interval_days
      @start_on = start_on
    end

    def next_due_at(last_completed_at:)
      return (start_on || Time.zone.today + interval_days).in_time_zone if last_completed_at.nil?

      (last_completed_at.to_date + interval_days).in_time_zone(last_completed_at.time_zone)
    end
  end
end
