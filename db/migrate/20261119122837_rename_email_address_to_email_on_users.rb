class RenameEmailAddressToEmailOnUsers < ActiveRecord::Migration[8.1]
  # Direct rename: no data in production yet, so no need for the multi-deploy procedure.
  def change
    rename_column :users, :email_address, :email
  end
end
