class AddImportanceToTasks < ActiveRecord::Migration[8.1]
  def change
    # Existing tasks (watering, manual plant tasks) are all flexible: the default fits them.
    add_column :tasks, :importance, :string, null: false, default: "flexible"
    # The occurrence reopened after a miss keeps its due date and is never missed again (Tasks::MarkMissed).
    add_column :task_occurrences, :reopened_after_miss, :boolean, null: false, default: false
  end
end
