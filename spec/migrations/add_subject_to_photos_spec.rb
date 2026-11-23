require "rails_helper"
require Rails.root.join("db/migrate/20261123140000_add_subject_to_photos")

# Data transformation (docs/tests.md): every existing photo keeps its plant, as its subject.
RSpec.describe AddSubjectToPhotos do
  let(:migration) { described_class.new.tap { _1.verbose = false } }

  it "makes the plant of every photo its subject, and goes back while all photos belong to a plant" do
    photo = create(:photo)
    migration.down
    Photo.reset_column_information

    migration.up
    Photo.reset_column_information

    expect(photo.reload).to have_attributes(subject_type: "Plant", subject_id: photo.plant_id)
  end

  it "refuses to go back once a photo belongs to something else than a plant" do
    create(:photo).update_columns(plant_id: nil)

    expect { migration.down }.to raise_error(ActiveRecord::IrreversibleMigration)
  end
end
