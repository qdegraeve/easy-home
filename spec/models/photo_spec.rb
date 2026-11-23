require "rails_helper"

RSpec.describe Photo, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  it "accepts a corrected day, at the start of that local day" do
    photo = build(:photo, taken_at: "2026-11-05")

    expect(photo).to be_valid
    expect(photo.taken_at).to eq(Time.zone.parse("2026-11-05 00:00"))
  end

  it "accepts today and rejects the future" do
    expect(build(:photo, taken_at: "2026-11-16")).to be_valid

    photo = build(:photo, taken_at: "2026-11-17")
    expect(photo).not_to be_valid
    expect(photo.errors.full_messages).to eq([ "Date de la photo ne peut pas être dans le futur" ])
  end

  it "requires a date" do
    expect(build(:photo, taken_at: "")).not_to be_valid
  end

  it "belongs to a subject of a known type, and says whose it is" do
    photo = create(:photo)

    expect(photo.of?(photo.plant)).to be(true)
    expect(photo.of?(create(:plant))).to be(false)
    expect(photo.of?(Household.new(id: photo.subject_id))).to be(false) # same id, another type
    photo.subject = create(:household)
    expect(photo).not_to be_valid
  end
end
