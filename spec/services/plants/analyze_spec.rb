require "rails_helper"

RSpec.describe Plants::Analyze do
  include ActiveSupport::Testing::TimeHelpers

  let(:analysis) { create(:plant_analysis) }
  let(:fake) { @fake_plant_analyzer }

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  it "stores the answer and marks the analysis done" do
    result = described_class.new.call(analysis:)

    expect(result).to be_success
    expect(analysis.reload).to have_attributes(
      status: "done", health: "watch", species_name: "Citrus limon", species_confidence: "high",
      watering_interval_days: 4, observations: FakePlantAnalyzer::ANSWER["observations"],
      finished_at: Time.current, error: nil
    )
    expect(analysis.actions.first).to include("title" => "Pailler le pied", "due_in_days" => 3)
  end

  it "sends the photos as JPEG of at most 1568 px, without metadata, with the context text" do
    analysis.photos.first.image.attach(io: file_fixture("plant_wide.webp").open, filename: "wide.webp")

    described_class.new.call(analysis:)

    call = fake.calls.sole
    image = Vips::Image.new_from_buffer(call[:images].sole, "")
    expect([ image.width, image.height ]).to eq([ 1568, 523 ])
    expect(image.get_fields.grep(/exif|gps|xmp/i)).to be_empty
    expect(call[:text]).to include("Plant: #{analysis.plant.name}.")
  end

  it "marks the analysis failed with the reason when the analyzer fails" do
    fake.error = "claude failed: Failed to authenticate"

    result = described_class.new.call(analysis:)

    expect(result.failure.first).to eq(:external_error)
    expect(analysis.reload).to have_attributes(status: "failed", health: nil)
    expect(analysis.error).to eq("external_error: claude failed: Failed to authenticate")
  end

  it "marks the analysis failed when the answer does not fit the schema" do
    fake.answer = FakePlantAnalyzer::ANSWER.merge("health" => "dying", "watering_interval_days" => 90)

    result = described_class.new.call(analysis:)

    expect(result.failure.first).to eq(:invalid_answer)
    expect(analysis.reload.error).to eq("invalid_answer: health, watering_interval_days")
  end

  it "fails without calling the analyzer when its photos were deleted" do
    analysis.photos.each(&:destroy!)

    result = described_class.new.call(analysis: analysis.reload)

    expect(result.failure.first).to eq(:no_photo)
    expect(analysis.reload).to have_attributes(status: "failed", error: "no_photo: the photos were deleted")
    expect(fake.calls).to be_empty
  end

  it "does nothing on an analysis that is not pending" do
    analysis.update!(status: :failed)

    expect(described_class.new.call(analysis:).failure.first).to eq(:not_pending)
    expect(fake.calls).to be_empty
  end

  it "refreshes the open plant pages" do
    expect { described_class.new.call(analysis:) }
      .to have_broadcasted_to(analysis.plant.to_gid_param).from_channel(Turbo::StreamsChannel)
  end
end
