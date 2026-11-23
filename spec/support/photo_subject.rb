# Contract of a subject of photos (ADR 0016): a plant today, an equipment and a task to come. Its photos are its own,
# the latest first, and go with it when it is deleted, files included.
RSpec.shared_examples "a photo subject" do
  it "keeps its photos, the latest first, and deletes them with their files when it is deleted" do
    older = create(:photo, plant: nil, subject:, taken_at: 2.days.ago)
    newer = create(:photo, plant: nil, subject:, taken_at: 1.day.ago)

    expect(subject.photos).to eq([ newer, older ])
    expect(older.of?(subject)).to be(true)

    blob_ids = subject.photos.map { _1.image.blob.id }
    perform_enqueued_jobs { subject.destroy! }

    expect(Photo.where(id: [ older.id, newer.id ])).to be_empty
    expect(ActiveStorage::Blob.where(id: blob_ids)).to be_empty
  end
end
