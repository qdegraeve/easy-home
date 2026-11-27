# ADR 0019: an invitation reserves a place in the household (a member without user yet) and carries the link that
# gives it to a person. Only the SHA-256 digest of the token is stored.
class CreateInvitations < ActiveRecord::Migration[8.1]
  def change
    change_column_null :household_members, :user_id, true
    add_column :household_members, :invitee_name, :string

    create_table :invitations do |t|
      t.references :household_member, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.string :token_digest, null: false, index: { unique: true }
      t.datetime :expires_at, null: false
      t.datetime :accepted_at
      t.timestamps
    end
  end
end
