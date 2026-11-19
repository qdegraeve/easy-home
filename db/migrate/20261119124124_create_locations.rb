class CreateLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :locations do |t|
      t.references :household, null: false, foreign_key: true, index: false
      t.string :name, null: false
      t.string :exposure, null: false
      t.boolean :sheltered, null: false, default: false
      t.timestamps
    end
    add_index :locations, [ :household_id, :name ], unique: true
  end
end
