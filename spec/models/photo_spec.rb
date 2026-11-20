require "rails_helper"

RSpec.describe Photo, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  let(:photo) { Photo.new(taken_at: Time.zone.parse("2026-11-12 18:30")) }

  describe "#taken_on=" do
    it "changes the day and keeps the time of day" do
      photo.taken_on = "2026-11-05"

      expect(photo.taken_at).to eq(Time.zone.parse("2026-11-05 18:30"))
      expect(photo.taken_on).to eq(Date.new(2026, 11, 5))
    end

    it "rejects a day in the future, but accepts today" do
      photo.taken_on = "2026-11-17"
      photo.validate
      expect(photo.errors[:taken_on]).to eq([ "ne peut pas être dans le futur" ])

      photo.taken_on = "2026-11-16"
      photo.validate
      expect(photo.errors[:taken_on]).to be_empty
    end

    it "rejects an unreadable date without changing the time" do
      photo.taken_on = "2026-02-30"
      photo.validate

      expect(photo.errors[:taken_on]).to be_present
      expect(photo.taken_at).to eq(Time.zone.parse("2026-11-12 18:30"))
    end
  end
end
