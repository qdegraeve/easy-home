# Reminder at a time on the due day (ADR 0017): the minute of the day on the task (05:00 to 22:00, quarter hours),
# and, on each occurrence, how many reminders were sent and when the last one left (follow-ups, no double send).
class AddRemindersToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :reminder_minute, :integer
    add_check_constraint :tasks,
      "reminder_minute IS NULL OR (reminder_minute BETWEEN 300 AND 1320 AND reminder_minute % 15 = 0)",
      name: "tasks_reminder_minute_quarter_hours"
    add_column :task_occurrences, :reminders_sent, :integer, default: 0, null: false
    add_column :task_occurrences, :last_reminded_at, :datetime
  end
end
