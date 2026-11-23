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

    period = recurrence.period_days
    (period * SHARE).round.clamp(0, MAX_DAYS) if period
  end

  # What a miss does to the task, once noted in the journal:
  # - :close, it is over, like once done (a one-off task that must not be missed: its day has passed);
  # - :reopen, still to do with the same due date, never missed again until done (a plant still needs water; a
  #   flexible task on fixed dates: a yearly one forgotten three days must not vanish for a year);
  # - :advance, the next date of its rule opens (the bins that must not be missed: a collection is never caught up).
  def self.after_miss(importance:, recurrence:)
    critical = importance.to_s == "critical"

    case recurrence
    when Recurrence::Once then :close
    when Recurrence::Fixed then critical ? :advance : :reopen
    else :reopen
    end
  end

  # A due date given by the app (a recomputation, a restored plant, a first watering long ago) never starts past its
  # tolerance: it would be missed at once, for something nobody could do. Never before today minus the grace days.
  def self.earliest(due_at, grace_days:, today:)
    return due_at if due_at.nil? || grace_days.nil?

    [ due_at, (today - grace_days).in_time_zone ].max
  end
end
