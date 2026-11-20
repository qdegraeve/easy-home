class CreatePlantAnalyses < ActiveRecord::Migration[8.1]
  def change
    create_table :plant_analyses do |t|
      t.references :plant, null: false, foreign_key: true, index: false
      t.references :requested_by, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "pending"
      t.text :user_note
      t.string :health
      t.string :species_name
      t.string :species_common_name
      t.string :species_confidence
      t.integer :watering_interval_days
      t.text :observations
      t.jsonb :actions, null: false, default: []
      t.string :error
      t.string :model
      t.datetime :finished_at

      t.timestamps
    end

    add_index :plant_analyses, [ :plant_id, :created_at ]
    # One analysis at a time per plant: a second request waits for the first one to finish.
    add_index(
      :plant_analyses,
      :plant_id,
      unique: true,
      where: "status = 'pending'",
      name: "index_plant_analyses_one_pending"
    )
  end
end
