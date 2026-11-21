# The photo chosen as the face of the plant (its page, the lists). Null: the latest photo. Deleting the photo clears it.
class AddCoverPhotoToPlants < ActiveRecord::Migration[8.1]
  def change
    add_reference :plants, :cover_photo, foreign_key: { to_table: :photos, on_delete: :nullify }
  end
end
