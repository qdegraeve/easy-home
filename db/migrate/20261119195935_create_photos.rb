class CreatePhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :photos do |t|
      t.references :plant, null: false, foreign_key: true, index: false
      t.datetime :taken_at, null: false

      t.timestamps
    end

    add_index :photos, [ :plant_id, :taken_at ]
  end
end
