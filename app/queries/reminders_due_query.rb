# The open occurrences whose reminder is due at `now` (ADR 0017): due today, of an active task with a reminder time,
# not reopened after a miss (its day has passed). The first reminder at the task's time; for a task that must not be
# missed, a follow-up every hour after it, three notifications at most; none after the cutoff hour. A late run (an
# outage) sends what is due once, never a burst: a follow-up waits at least FOLLOW_UP_GAP after the previous one.
class RemindersDueQuery
  MAX_SENT = 3
  CUTOFF_MINUTE = 22 * 60
  # Just under an hour: the job runs every 5 minutes, a follow-up leaves at 20:00 or 20:05, not 20:10.
  FOLLOW_UP_GAP = 55.minutes

  def initialize(relation = TaskOccurrence.all)
    @relation = relation
  end

  def call(now: Time.current)
    today = now.in_time_zone.to_date
    @relation.pending.where(reopened_after_miss: false, due_at: today.all_day)
      .joins(:task).merge(Task.active).where.not(tasks: { reminder_minute: nil })
      .where(<<~SQL.squish, now:)
        task_occurrences.due_at
          + make_interval(mins => tasks.reminder_minute, hours => task_occurrences.reminders_sent) <= :now
      SQL
      .where("task_occurrences.due_at + make_interval(mins => :cutoff) > :now", cutoff: CUTOFF_MINUTE, now:)
      .where(<<~SQL.squish, max: MAX_SENT, gap: now - FOLLOW_UP_GAP)
        task_occurrences.reminders_sent = 0
        OR (tasks.importance = 'critical' AND task_occurrences.reminders_sent < :max
            AND task_occurrences.last_reminded_at <= :gap)
      SQL
  end
end
