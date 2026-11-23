require "rails_helper"
require Rails.root.join("db/migrate/20261124100000_require_subject_of_photos")

# Data transformation (docs/tests.md): a photo still without a subject gets its plant back, then the subject is
# required in the database.
RSpec.describe RequireSubjectOfPhotos do
  let(:migration) { described_class.new.tap { _1.verbose = false } }
  let(:connection) { ActiveRecord::Base.connection }

  it "gives its plant back to a photo without a subject, then requires the subject" do
    photo = create(:photo)
    migration.down
    connection.execute("UPDATE photos SET plant_id = subject_id, subject_type = NULL, subject_id = NULL")

    migration.up

    expect(photo.reload).to have_attributes(subject_type: "Plant", subject_id: photo.subject_id)
    expect(connection.select_value("SELECT subject_id FROM photos WHERE id = #{photo.id}")).to eq(photo.subject_id)
    expect { connection.execute("UPDATE photos SET subject_id = NULL") }.to raise_error(ActiveRecord::NotNullViolation)
  end
end
