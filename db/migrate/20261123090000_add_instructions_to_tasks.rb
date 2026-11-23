# "Comment faire" of a task (docs/conception/equipements-et-taches.md): the steps, read when doing it. Optional.
class AddInstructionsToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :instructions, :text
  end
end
