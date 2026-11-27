# ADR 0019: what a guest may see and do. A subject opened (a plant, an equipment, or the household for the tasks of
# the house), or everything ("Tout ouvrir"), during an optional period carried by the guest's place.
class CreateGuestAccesses < ActiveRecord::Migration[8.1]
  def change
    change_table :household_members, bulk: true do |t|
      t.boolean :guest_full_access, null: false, default: false
      t.date :access_starts_on
      t.date :access_ends_on
    end

    create_table :guest_accesses do |t|
      t.references :household_member, null: false, foreign_key: { on_delete: :cascade }
      t.references :subject, polymorphic: true, null: false
      t.timestamps
      t.index [ :household_member_id, :subject_type, :subject_id ], unique: true, name: "index_guest_accesses_unique"
    end
  end
end
