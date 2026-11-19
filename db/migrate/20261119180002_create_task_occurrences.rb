class CreateTaskOccurrences < ActiveRecord::Migration[8.1]
  def change
    create_table :task_occurrences do |t|
      t.references :task, null: false, foreign_key: true, index: false
      t.datetime :due_at, null: false
      t.string :status, null: false, default: "pending"
      t.references :completed_by, foreign_key: { to_table: :users }
      t.datetime :completed_at

      t.timestamps
    end

    add_index :task_occurrences, [ :task_id, :due_at ]
    # One open occurrence per task: two concurrent completions cannot create two next occurrences.
    add_index(
      :task_occurrences,
      :task_id,
      unique: true,
      where: "status = 'pending'",
      name: "index_task_occurrences_one_pending"
    )
  end
end
