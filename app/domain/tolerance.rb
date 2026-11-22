# Tolerance of a late task (UX review, mechanism 4): the days an occurrence stays to do after its due day, before it
# is missed. A task that must not be missed has none. A flexible one gets a share of its interval: a plant watered
# every day is late sooner than one watered every week (1 day: 0, 3 days: 1, 7 days: 2, 14 days and more: 3). A
# flexible one-off task is never missed: it stays to do until done or deleted.
module Tolerance
  SHARE = 0.25
  MAX_DAYS = 3

  # Grace days, or nil when never missed.
  def self.grace_days(importance:, recurrence:)
    return 0 if importance.to_s == "critical"

    case recurrence
    when Recurrence::Sliding then (recurrence.interval_days * SHARE).round.clamp(0, MAX_DAYS)
    end
  end
end
