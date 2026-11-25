require "rails_helper"
require Rails.root.join("db/migrate/20261124100000_require_subject_of_photos")

# Data transformation (docs/tests.md): a photo still without a subject gets its plant back, then the subject is
# required in the database; a photo with a subject keeps it.
RSpec.describe RequireSubjectOfPhotos do
  let(:migration) { described_class.new.tap { _1.verbose = false } }
  let(:connection) { ActiveRecord::Base.connection }

  def columns_of(photo)
    connection.select_one("SELECT subject_type, subject_id, plant_id FROM photos WHERE id = #{photo.id}")
  end

  it "gives its plant back to a photo without a subject, keeps the others, then requires the subject" do
    plant = create(:plant)
    orphan = create(:photo, plant:)
    task = create(:task)
    of_task = create(:photo, subject: task)
    migration.down
    expect(columns_of(orphan)).to include("plant_id" => plant.id) # restored for the previous code
    connection.execute("UPDATE photos SET subject_type = NULL, subject_id = NULL WHERE id = #{orphan.id}")
    connection.execute("UPDATE photos SET plant_id = #{plant.id} WHERE id = #{of_task.id}")

    migration.up

    expect(columns_of(orphan)).to include("subject_type" => "Plant", "subject_id" => plant.id)
    expect(columns_of(of_task)).to include("subject_type" => "Task", "subject_id" => task.id)
    expect(connection.foreign_key_exists?(:photos, :plants)).to be(false)
    expect { connection.execute("UPDATE photos SET subject_id = NULL") }.to raise_error(ActiveRecord::NotNullViolation)
  end
end
