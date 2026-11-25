# A task has a whole subject or none (a task of the house): never a type without an id, or the reverse.
class AddSubjectConsistencyToTasks < ActiveRecord::Migration[8.1]
  def change
    add_check_constraint :tasks, "(subject_type IS NULL) = (subject_id IS NULL)", name: "tasks_subject_whole_or_none"
  end
end
