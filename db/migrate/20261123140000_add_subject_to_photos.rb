# Photos of anything, not only plants (ADR 0016): a polymorphic subject (Plant, Equipment, Task), filled for the
# existing photos from plant_id. plant_id stays, still written for the photos of a plant, so that the code before
# this change keeps working during a deploy; it goes away, and the subject becomes required in the database, once
# nothing reads it (PR 9). The model already requires the subject.
class AddSubjectToPhotos < ActiveRecord::Migration[8.1]
  def up
    add_column :photos, :subject_type, :string
    add_column :photos, :subject_id, :bigint
    execute "UPDATE photos SET subject_type = 'Plant', subject_id = plant_id"
    add_index :photos, [ :subject_type, :subject_id, :taken_at ]
    change_column_null :photos, :plant_id, true
  end

  def down
    if select_value("SELECT 1 FROM photos WHERE plant_id IS NULL")
      raise ActiveRecord::IrreversibleMigration, "Some photos belong to something else than a plant"
    end

    change_column_null :photos, :plant_id, false
    remove_index :photos, [ :subject_type, :subject_id, :taken_at ]
    remove_column :photos, :subject_id
    remove_column :photos, :subject_type
  end
end
