class AddImportanceToTasks < ActiveRecord::Migration[8.1]
  def change
    # Existing tasks (watering, manual plant tasks) are all flexible: the default fits them.
    add_column :tasks, :importance, :string, null: false, default: "flexible"
  end
end
