class CreatePlantAnalysisPhotos < ActiveRecord::Migration[8.1]
  def change
    create_table :plant_analysis_photos do |t|
      t.references :plant_analysis, null: false, foreign_key: true, index: false
      t.references :photo, null: false, foreign_key: true

      t.timestamps
    end

    add_index :plant_analysis_photos, [ :plant_analysis_id, :photo_id ], unique: true
  end
end
