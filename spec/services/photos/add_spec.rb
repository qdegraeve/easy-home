require "rails_helper"

RSpec.describe Photos::Add do
  include ActiveSupport::Testing::TimeHelpers

  let(:plant) { create(:plant) }

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  def upload(name)
    Rack::Test::UploadedFile.new(file_fixture(name))
  end

  def stored_image(photo)
    photo.image.blob.open { |file| Vips::Image.new_from_file(file.path) }
  end

  it "stores the photo as a JPEG without any metadata (no EXIF GPS)" do
    expect(Vips::Image.new_from_file(file_fixture("plant_with_gps.jpg").to_s).get_fields).to include(/GPS/)

    photo = described_class.new.call(plant:, file: upload("plant_with_gps.jpg")).value!

    expect(photo).to have_attributes(plant:, taken_at: Time.zone.parse("2026-11-16 10:00"))
    expect(photo.image.blob.content_type).to eq("image/jpeg")
    expect(stored_image(photo).get_fields.grep(/exif|gps|xmp|iptc/i)).to be_empty
  end

  it "accepts PNG and WebP, and shrinks large pictures to 2048 px" do
    expect(described_class.new.call(plant:, file: upload("plant.png"))).to be_success

    photo = described_class.new.call(plant:, file: upload("plant_wide.webp")).value!

    expect(stored_image(photo)).to have_attributes(width: 2048, height: 683)
  end

  it "rejects a file that is not a picture, whatever its name" do
    result = described_class.new.call(plant:, file: upload("not_an_image.jpg"))

    expect(result.failure.first).to eq(:invalid)
    expect(result.failure.last.errors.full_messages).to eq([ "Photo n'est pas une image JPEG, PNG ou WebP lisible" ])
    expect(plant.photos).to be_empty
  end

  it "rejects a file over 15 MB" do
    file = upload("plant.png")
    allow(file).to receive(:size).and_return(15.megabytes + 1)

    result = described_class.new.call(plant:, file:)

    expect(result.failure.last.errors.full_messages).to eq([ "Photo dépasse 15 Mo" ])
  end

  it "rejects a missing file" do
    expect(described_class.new.call(plant:, file: nil).failure.first).to eq(:invalid)
  end

  it "rejects an archived plant" do
    plant.update!(archived_at: Time.current)

    expect(described_class.new.call(plant:, file: upload("plant.png")).failure.first).to eq(:subject_archived)
    expect(plant.photos).to be_empty
  end
end
