class AddAddressToHouseholds < ActiveRecord::Migration[8.1]
  def change
    add_column :households, :address, :string
    add_column :households, :latitude, :decimal, precision: 9, scale: 6
    add_column :households, :longitude, :decimal, precision: 9, scale: 6
    add_column :households, :altitude_m, :integer
  end
end
