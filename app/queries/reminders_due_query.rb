# The open occurrences whose reminder is due at `now` (ADR 0017): due today, of an active task with a reminder time,
# not reopened after a miss (its day has passed).
# - The first reminder at the task's time; for a task that must not be missed, a follow-up every hour after it, three
#   notifications at most. None is planned after CUTOFF_MINUTE (22:00 is the last planned one), and none leaves after
#   it but within the few minutes of the run that sends a 22:00 reminder.
# - The counters count for the due day only (sent since its start): an occurrence moved to another day starts again.
# - A late run (an outage) sends what is due once, never a burst: a follow-up waits at least FOLLOW_UP_GAP after the
#   previous one.
# Times are the start of the local day (due_at) plus minutes: the application time zone, without daylight saving
# (Indian/Reunion), like every due date of the app.
class RemindersDueQuery
  MAX_SENT = 3
  CUTOFF_MINUTE = 22 * 60
  # The run that sends a reminder planned at 22:00 may come a few minutes after it.
  CUTOFF_GRACE = 15.minutes
  # Just under an hour: the job runs every 5 minutes, a follow-up leaves at 20:00 or 20:05, not 20:10.
  FOLLOW_UP_GAP = 55.minutes
  # Reminders sent for the due day of the occurrence (counters left from another day count for nothing).
  SENT = <<~SQL.squish.freeze
    (CASE WHEN task_occurrences.last_reminded_at >= task_occurrences.due_at
      THEN task_occurrences.reminders_sent ELSE 0 END)
  SQL

  def initialize(relation = TaskOccurrence.all)
    @relation = relation
  end

  # sent: only when that many reminders were sent for the day (to claim a send atomically).
  def call(now: Time.current, sent: nil)
    today = now.in_time_zone.to_date
    @relation.pending.where(reopened_after_miss: false, due_at: today.all_day)
      .joins(:task).merge(Task.active).where.not(tasks: { reminder_minute: nil })
      .where("tasks.reminder_minute + 60 * #{SENT} <= :cutoff", cutoff: CUTOFF_MINUTE)
      .where("task_occurrences.due_at + make_interval(mins => tasks.reminder_minute + 60 * #{SENT}) <= :now", now:)
      .where("task_occurrences.due_at + make_interval(mins => :latest) > :now",
             latest: CUTOFF_MINUTE + CUTOFF_GRACE.in_minutes.to_i, now:)
      .where(<<~SQL.squish, critical: Task.importances[:critical], max: MAX_SENT, gap: now - FOLLOW_UP_GAP)
        #{SENT} = 0
        OR (tasks.importance = :critical AND #{SENT} < :max AND task_occurrences.last_reminded_at <= :gap)
      SQL
      .then { |relation| sent.nil? ? relation : relation.where("#{SENT} = :sent", sent:) }
  end

  # The number of reminders already sent for the due day of an occurrence.
  def self.sent(occurrence_id)
    TaskOccurrence.where(id: occurrence_id).pick(Arel.sql(SENT))
  end
end
