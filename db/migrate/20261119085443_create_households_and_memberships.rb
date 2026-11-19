class CreateHouseholdsAndMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :households do |t|
      t.string :name, null: false
      t.string :time_zone, null: false, default: "Indian/Reunion"
      t.timestamps
    end

    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :household, null: false, foreign_key: true
      t.string :role, null: false
      t.timestamps
    end
    add_index :memberships, [ :user_id, :household_id ], unique: true
  end
end
