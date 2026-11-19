class CreatePlants < ActiveRecord::Migration[8.1]
  def change
    create_table :plants do |t|
      t.references :household, null: false, foreign_key: true
      t.references :location, foreign_key: true
      t.string :name, null: false
      t.string :species
      t.string :species_source
      t.datetime :archived_at

      t.timestamps
    end
  end
end
