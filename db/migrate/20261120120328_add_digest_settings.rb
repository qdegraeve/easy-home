# The morning digest of the tasks due (ADR 0012): settings per user, choice per household, and one digest a day at
# most. A device token is unique: a phone signed in again by someone else moves to that user.
class AddDigestSettings < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.boolean :digest_enabled, null: false, default: true
      t.integer :digest_minute, null: false, default: 8 * 60 # minutes after midnight, in the app time zone
      t.date :last_digest_on
    end
    add_column :household_members, :digest, :boolean, null: false, default: true
    add_index :action_push_native_devices, :token, unique: true
  end
end
