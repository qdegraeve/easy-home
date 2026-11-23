# The open occurrences by due date: read every few minutes by the reminders and the digest (RemindersDueQuery,
# DueOccurrencesQuery), every hour by Tasks::MarkMissed and each evening by the rain, while closed ones pile up.
class AddPendingDueAtIndexToTaskOccurrences < ActiveRecord::Migration[8.1]
  def change
    add_index :task_occurrences, :due_at, where: "status = 'pending'", name: "index_task_occurrences_pending_due_at"
  end
end
