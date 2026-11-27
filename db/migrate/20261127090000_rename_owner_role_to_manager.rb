# ADR 0019: "owner" becomes "manager" (gestionnaire), and a household may have several of them.
class RenameOwnerRoleToManager < ActiveRecord::Migration[8.1]
  def up
    execute("UPDATE household_members SET role = 'manager' WHERE role = 'owner'")
  end

  def down
    execute("UPDATE household_members SET role = 'owner' WHERE role = 'manager'")
  end
end
