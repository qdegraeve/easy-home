# The suggestion of the catalogue a task was created from (config/catalogue.yml, e.g. "bins.yellow"): its origin only,
# no behavior depends on it (ADR 0016).
class AddSuggestionKeyToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :suggestion_key, :string
  end
end
