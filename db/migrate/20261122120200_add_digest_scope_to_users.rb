class AddDigestScopeToUsers < ActiveRecord::Migration[8.1]
  def change
    # all: every task due today or late; critical: only the tasks that must not be missed (UX review #22).
    add_column :users, :digest_scope, :string, null: false, default: "all"
  end
end
