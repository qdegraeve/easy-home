# ADR 0020: an invitation is sent to an e-mail address, and only that address can take it. Clicking the link proves
# the address: no separate confirmation.
class AddEmailToInvitations < ActiveRecord::Migration[8.1]
  def change
    add_column :invitations, :email, :string
  end
end
