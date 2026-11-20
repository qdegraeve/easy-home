require "rails_helper"

RSpec.describe Plants::RequestAnalysis do
  include ActiveJob::TestHelper

  let(:plant) { create(:plant) }
  let(:user) { create(:household_member, household: plant.household).user }
  let!(:old_photo) { create(:photo, plant:, taken_at: 3.days.ago) }
  let!(:new_photo) { create(:photo, plant:, taken_at: 1.day.ago) }

  it "analyses the latest photo by default, and queues the job" do
    analysis = nil

    expect { analysis = described_class.new.call(plant:, user:).value! }
      .to have_enqueued_job(AnalyzePlantJob)

    expect(analysis).to have_attributes(status: "pending", requested_by: user, user_note: nil, photos: [ new_photo ])
  end

  it "analyses the chosen photos with the user's note" do
    analysis = described_class.new.call(
      plant:, user:, params: { photo_ids: [ old_photo.id.to_s, new_photo.id.to_s, "" ], note: " Feuilles jaunes ? " }
    ).value!

    expect(analysis.photos).to contain_exactly(old_photo, new_photo)
    expect(analysis.user_note).to eq("Feuilles jaunes ?")
  end

  it "refuses more than 5 photos" do
    photos = create_list(:photo, 4, plant:)
    ids = (photos + [ old_photo, new_photo ]).map(&:id)

    result = described_class.new.call(plant:, user:, params: { photo_ids: ids })

    expect(result.failure.last.errors.full_messages).to eq([ "Photos à analyser : 5 au maximum" ])
    expect(PlantAnalysis.count).to eq(0)
  end

  it "refuses a photo of another plant" do
    result = described_class.new.call(plant:, user:, params: { photo_ids: [ create(:photo).id ] })

    expect(result.failure.last.errors.full_messages)
      .to eq([ "Photos à analyser : choisissez parmi les photos de cette plante" ])
  end

  it "refuses a plant without photo, an archived plant, and a second analysis while one is pending" do
    expect(described_class.new.call(plant: create(:plant), user:).failure.first).to eq(:invalid)

    described_class.new.call(plant:, user:)
    expect(described_class.new.call(plant:, user:).failure.first).to eq(:already_pending)

    plant.update!(archived_at: Time.current)
    expect(described_class.new.call(plant:, user:).failure.first).to eq(:subject_archived)
  end
end
