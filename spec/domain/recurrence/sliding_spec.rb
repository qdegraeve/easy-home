require "rails_helper"

RSpec.describe Recurrence::Sliding do
  let(:zone) { ActiveSupport::TimeZone["Indian/Reunion"] }

  def next_due(interval, last_completed_at)
    described_class.new(interval:).next_due_at(last_completed_at:)
  end

  describe "#next_due_at" do
    it "falls interval_days days after the completion, at the start of the day" do
      expect(next_due(3, zone.parse("2026-11-16 18:42"))).to eq(zone.parse("2026-11-19 00:00"))
    end

    it "keeps the time zone of the completion (Indian/Reunion, UTC+4)" do
      due = next_due(1, zone.parse("2026-11-16 02:00"))

      expect(due.time_zone).to eq(zone)
      expect(due.utc).to eq(Time.utc(2026, 11, 16, 20, 0))
    end

    it "counts the local day, even when the completion is the day before in UTC" do
      # 2026-11-17 01:00 in Reunion = 2026-11-16 21:00 UTC
      expect(next_due(2, zone.parse("2026-11-17 01:00"))).to eq(zone.parse("2026-11-19 00:00"))
    end

    it "crosses the end of a month and of a year" do
      expect(next_due(3, zone.parse("2026-11-29 08:00"))).to eq(zone.parse("2026-12-02 00:00"))
      expect(next_due(5, zone.parse("2026-12-30 08:00"))).to eq(zone.parse("2027-01-04 00:00"))
    end

    it "counts February 29 in a leap year, not in a common year" do
      expect(next_due(1, zone.parse("2028-02-28 08:00"))).to eq(zone.parse("2028-02-29 00:00"))
      expect(next_due(1, zone.parse("2027-02-28 08:00"))).to eq(zone.parse("2027-03-01 00:00"))
    end

    it "accepts the 1 and 60 day bounds" do
      expect(next_due(1, zone.parse("2026-11-16 23:59"))).to eq(zone.parse("2026-11-17 00:00"))
      expect(next_due(60, zone.parse("2026-11-16 00:00"))).to eq(zone.parse("2027-01-15 00:00"))
    end

    it "stays at local midnight across a DST change (zone with daylight saving)" do
      paris = ActiveSupport::TimeZone["Europe/Paris"]

      expect(next_due(2, paris.parse("2026-03-28 10:00"))).to eq(paris.parse("2026-03-30 00:00"))
    end
  end

  describe "never done" do
    include ActiveSupport::Testing::TimeHelpers

    around { |example| travel_to(zone.parse("2026-11-16 22:30")) { example.run } }

    it "starts from the start date when set, even in the past" do
      later = described_class.new(interval: 14, start_on: Date.new(2026, 11, 20))
      past = described_class.new(interval: 14, start_on: Date.new(2026, 11, 1))

      expect(later.next_due_at(last_completed_at: nil)).to eq(zone.parse("2026-11-20 00:00"))
      expect(past.next_due_at(last_completed_at: nil)).to eq(zone.parse("2026-11-01 00:00"))
    end

    it "falls interval_days days from today (local day) without a start date" do
      expect(described_class.new(interval: 3).next_due_at(last_completed_at: nil))
        .to eq(zone.parse("2026-11-19 00:00"))
    end

    it "ignores the start date once done" do
      recurrence = described_class.new(interval: 2, start_on: Date.new(2026, 12, 25))

      expect(recurrence.next_due_at(last_completed_at: zone.parse("2026-11-16 08:00")))
        .to eq(zone.parse("2026-11-18 00:00"))
    end

    it "rejects a start date that is not a date" do
      expect { described_class.new(interval: 2, start_on: "2026-11-20") }.to raise_error(Recurrence::InvalidConfig)
    end
  end

  describe "invalid interval" do
    [ 0, 61, -1, nil, "3", 2.5 ].each do |value|
      it "rejects #{value.inspect}" do
        expect { described_class.new(interval: value) }.to raise_error(Recurrence::InvalidConfig)
      end
    end
  end

  describe "weeks, months and years" do
    def next_on(interval, unit, done_on)
      described_class.new(interval:, unit:).next_due_at(last_completed_at: done_on.in_time_zone).to_date
    end

    it "counts N weeks, months or years after the last time" do
      expect(next_on(2, "weeks", Date.new(2026, 11, 16))).to eq(Date.new(2026, 11, 30))
      expect(next_on(3, "months", Date.new(2026, 11, 16))).to eq(Date.new(2027, 2, 16))
      expect(next_on(2, "years", Date.new(2026, 11, 16))).to eq(Date.new(2028, 11, 16))
    end

    it "falls on the last day of a shorter month, and on February 28th after a 29th" do
      expect(next_on(1, "months", Date.new(2027, 1, 31))).to eq(Date.new(2027, 2, 28))
      expect(next_on(1, "years", Date.new(2028, 2, 29))).to eq(Date.new(2029, 2, 28))
    end

    it "has a period for the tolerance, and an interval in days only for a rule in days" do
      expect(described_class.new(interval: 3, unit: "months").period_days).to eq(90)
      expect(described_class.new(interval: 2, unit: "weeks").period_days).to eq(14)
      expect(described_class.new(interval: 3, unit: "months").interval_days).to be_nil
      expect(described_class.new(interval: 3).interval_days).to eq(3)
    end

    it "refuses an interval out of the bounds of its unit" do
      expect { described_class.new(interval: 61, unit: "days") }.to raise_error(Recurrence::InvalidConfig)
      expect { described_class.new(interval: 25, unit: "months") }.to raise_error(Recurrence::InvalidConfig)
      expect { described_class.new(interval: 11, unit: "years") }.to raise_error(Recurrence::InvalidConfig)
      expect { described_class.new(interval: 1, unit: "hours") }.to raise_error(Recurrence::InvalidConfig)
    end
  end
end
