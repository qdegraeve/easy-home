require "rails_helper"

RSpec.describe Plants::Add do
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household) }
  let(:user) { create(:household_member, household:).user }
  let(:location) { create(:location, household:) }
  let(:params) do
    { name: "Hibiscus", species: "Hibiscus rosa-sinensis", location_id: location.id.to_s,
      watering_interval_days: "3", last_watered_on: "2026-11-14" }
  end

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  it "creates the plant, its watering task, the last watering in the log and the next occurrence" do
    result = described_class.new.call(household:, user:, params:)

    plant = result.value!
    expect(plant).to have_attributes(name: "Hibiscus", species: "Hibiscus rosa-sinensis", location:)
    expect(plant).to be_species_from_user
    task = plant.watering_task
    expect(task).to have_attributes(household:, recurrence_type: "sliding", recurrence_config: { "interval_days" => 3 })
    expect(task.occurrences.done.sole).to have_attributes(
      completed_at: Time.zone.parse("2026-11-14"),
      completed_by: user
    )
    expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-17 00:00"))
  end

  it "starts from today without a last watering, species or location" do
    plant = described_class.new.call(
      household:, user:, params: { name: "Basilic", watering_interval_days: "2" }
    ).value!

    expect(plant).to have_attributes(species: nil, species_source: nil, location: nil)
    expect(plant.watering_task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-18 00:00"))
  end

  {
    "without a name" => { name: " " },
    "with a 0 interval" => { watering_interval_days: "0" },
    "with an interval over 60" => { watering_interval_days: "61" },
    "with a non numeric interval" => { watering_interval_days: "abc" },
    "with a last watering in the future" => { last_watered_on: "2026-11-17" }
  }.each do |label, override|
    it "rejects an input #{label}, without creating anything" do
      result = nil

      expect { result = described_class.new.call(household:, user:, params: params.merge(override)) }
        .not_to change(Plant, :count)
      expect(result).to be_failure
      expect(result.failure.first).to eq(:invalid)
    end
  end

  it "uses today when the last watering is emptied" do
    plant = described_class.new.call(household:, user:, params: params.merge(last_watered_on: "")).value!

    expect(plant.watering_task.occurrences.done.sole.completed_at).to eq(Time.zone.parse("2026-11-16 00:00"))
    expect(plant.watering_task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-19 00:00"))
  end

  it "adds the optional first photo" do
    plant = described_class.new.call(
      household:, user:, params: params.merge(photo: Rack::Test::UploadedFile.new(file_fixture("plant.png")))
    ).value!

    expect(plant.photos.sole.image).to be_attached
  end

  it "rejects a photo that is not a picture, without creating the plant" do
    result = described_class.new.call(
      household:, user:, params: params.merge(photo: Rack::Test::UploadedFile.new(file_fixture("not_an_image.jpg")))
    )

    expect(result.failure.last.errors.full_messages).to eq([ "Photo n'est pas une image JPEG, PNG ou WebP lisible" ])
    expect(Plant.count).to eq(0)
  end

  it "rolls everything back when the photo passes the form checks but cannot be processed" do
    photo = truncated_jpeg
    expect(PhotoUpload.new(file: photo)).to be_valid

    result = described_class.new.call(household:, user:, params: params.merge(photo:))

    expect(result.failure.last.errors.full_messages).to eq([ "Photo n'est pas une image JPEG, PNG ou WebP lisible" ])
    expect(Plant.count).to eq(0)
    expect(Task.count).to eq(0)
  end

  it "rejects a location of another household" do
    result = described_class.new.call(household:, user:, params: params.merge(location_id: create(:location).id.to_s))

    expect(result.failure.last.errors[:location_id]).to be_present
    expect(Plant.count).to eq(0)
  end
end
