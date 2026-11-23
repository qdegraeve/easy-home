# Second step of the polymorphic photos (ADR 0016, after AddSubjectToPhotos): once the code that wrote and read
# photos.plant_id is no longer in production, the subject becomes required in the database. Any photo left without
# one (none expected) gets its plant back as its subject first. The former column is ignored by the model; it is
# dropped in a later deploy, so that the code before this one keeps working while it is deployed.
class RequireSubjectOfPhotos < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE photos SET subject_type = 'Plant', subject_id = plant_id
      WHERE subject_id IS NULL AND plant_id IS NOT NULL
    SQL
    change_column_null :photos, :subject_type, false
    change_column_null :photos, :subject_id, false
    remove_foreign_key :photos, :plants
    remove_index :photos, [ :plant_id, :taken_at ]
  end

  def down
    add_index :photos, [ :plant_id, :taken_at ]
    add_foreign_key :photos, :plants
    change_column_null :photos, :subject_id, true
    change_column_null :photos, :subject_type, true
  end
end
