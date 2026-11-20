# Positions of the actions of an analysis already turned into tasks: each action is applied at most once.
class AddAppliedActionIndexesToPlantAnalyses < ActiveRecord::Migration[8.1]
  def change
    add_column :plant_analyses, :applied_action_indexes, :integer, array: true, default: [], null: false
  end
end
