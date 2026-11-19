class RenameEmailAddressToEmailOnUsers < ActiveRecord::Migration[8.1]
  # Renommage direct : aucune donnée en production, donc pas besoin de la procédure en plusieurs déploiements.
  def change
    rename_column :users, :email_address, :email
  end
end
