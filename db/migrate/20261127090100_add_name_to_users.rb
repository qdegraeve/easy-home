# The first name shown in the journal ("Fait par Léa") and in the list of the members (ADR 0019).
class AddNameToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string
  end
end
