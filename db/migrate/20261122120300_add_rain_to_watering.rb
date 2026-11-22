# Rain counts as a watering (ADR 0015): the locations that get the rain, who closed an occurrence (a person or the
# rain), and the daily rainfall of each household, fetched once in the evening.
class AddRainToWatering < ActiveRecord::Migration[8.1]
  def change
    # Off for the existing locations: nothing is watered by the rain until the owner says that a place gets it.
    add_column :locations, :rain_exposed, :boolean, default: false, null: false
    add_column :task_occurrences, :source, :string, default: "manual", null: false

    create_table :rainfalls do |t|
      t.references :household, null: false, foreign_key: true
      t.date :on, null: false
      t.decimal :millimeters, precision: 5, scale: 1, null: false
      t.timestamps
    end
    add_index :rainfalls, [ :household_id, :on ], unique: true
  end
end
