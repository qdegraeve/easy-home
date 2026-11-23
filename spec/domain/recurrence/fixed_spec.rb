require "rails_helper"

RSpec.describe Recurrence::Fixed do
  def fixed(anchor_on, interval, unit)
    described_class.new(anchor_on:, interval:, unit:)
  end

  def next_due_on(rule, last_completed_on: nil, last_due_on: nil, not_before: nil)
    rule.next_due_at(last_completed_at: last_completed_on&.in_time_zone, last_due_on:, not_before:).to_date
  end

  # The yellow bin, every other Tuesday from Tuesday December 1st 2026.
  let(:bins) { fixed(Date.new(2026, 12, 1), 2, "weeks") }

  describe "every N weeks" do
    it "opens on the anchor when nothing happened yet, even with an earlier floor" do
      expect(next_due_on(bins)).to eq(Date.new(2026, 12, 1))
      expect(next_due_on(bins, not_before: Date.new(2026, 11, 20))).to eq(Date.new(2026, 12, 1))
    end

    it "keeps the weekday of the anchor, two weeks later after a completion on the day, early or late" do
      { Date.new(2026, 12, 1) => Date.new(2026, 12, 15),   # on the day
        Date.new(2026, 11, 30) => Date.new(2026, 12, 15),  # the evening before
        Date.new(2026, 12, 3) => Date.new(2026, 12, 15) }  # two days late
        .each do |done_on, expected|
          expect(next_due_on(bins, last_completed_on: done_on, last_due_on: Date.new(2026, 12, 1))).to eq(expected)
        end
    end

    it "comes back to the rule after a postponed date done the next day" do
      expect(next_due_on(bins, last_completed_on: Date.new(2026, 12, 2), last_due_on: Date.new(2026, 12, 2)))
        .to eq(Date.new(2026, 12, 15))
    end

    it "skips the dates before the floor: a missed collection is not caught up" do
      expect(next_due_on(bins, last_due_on: Date.new(2026, 12, 1), not_before: Date.new(2026, 12, 2)))
        .to eq(Date.new(2026, 12, 15))
      expect(next_due_on(bins, last_due_on: Date.new(2026, 12, 1), not_before: Date.new(2027, 1, 20)))
        .to eq(Date.new(2027, 1, 26))
    end

    it "steps over the end of the year and keeps a weekly rule on its weekday" do
      weekly = fixed(Date.new(2026, 12, 29), 1, "weeks")

      expect(next_due_on(weekly, last_due_on: Date.new(2026, 12, 29))).to eq(Date.new(2027, 1, 5))
      expect(next_due_on(weekly, not_before: Date.new(2027, 3, 4)).wday).to eq(Date.new(2026, 12, 29).wday)
    end

    it "opens a past anchor on its first date not before the floor" do
      past = fixed(Date.new(2026, 10, 6), 2, "weeks")

      expect(next_due_on(past, not_before: Date.new(2026, 11, 16))).to eq(Date.new(2026, 11, 17))
      expect(next_due_on(past, not_before: Date.new(2026, 11, 17))).to eq(Date.new(2026, 11, 17))
    end
  end

  describe "every N years" do
    let(:cyclone_season) { fixed(Date.new(2026, 11, 1), 1, "years") }

    it "comes back on the same day the next year, done early, on the day or late" do
      [ Date.new(2026, 10, 25), Date.new(2026, 11, 1), Date.new(2026, 11, 10) ].each do |done_on|
        expect(next_due_on(cyclone_season, last_completed_on: done_on, last_due_on: Date.new(2026, 11, 1)))
          .to eq(Date.new(2027, 11, 1))
      end
    end

    it "every other year, and over several years without anything done" do
      every_two = fixed(Date.new(2026, 5, 1), 2, "years")

      expect(next_due_on(every_two, last_due_on: Date.new(2026, 5, 1))).to eq(Date.new(2028, 5, 1))
      expect(next_due_on(every_two, not_before: Date.new(2031, 6, 1))).to eq(Date.new(2032, 5, 1))
    end

    it "falls on February 28th the years without a 29th, then back on the 29th" do
      leap = fixed(Date.new(2028, 2, 29), 1, "years")

      expect(next_due_on(leap, last_due_on: Date.new(2028, 2, 29))).to eq(Date.new(2029, 2, 28))
      expect(next_due_on(leap, not_before: Date.new(2031, 3, 1))).to eq(Date.new(2032, 2, 29))
    end
  end

  it "returns the start of the local day" do
    due_at = bins.next_due_at(last_completed_at: nil)

    expect(due_at).to eq(Time.zone.parse("2026-12-01 00:00"))
    expect(due_at.time_zone).to eq(Time.zone)
  end

  it "has a period for the tolerance, and due dates" do
    expect(bins.period_days).to eq(14)
    expect(fixed(Date.new(2026, 11, 1), 1, "years").period_days).to eq(365)
    expect(bins).to be_dated
  end

  it "refuses an invalid rule" do
    expect { fixed("2026-12-01", 2, "weeks") }.to raise_error(Recurrence::InvalidConfig)
    expect { fixed(Date.new(2026, 12, 1), 2, "months") }.to raise_error(Recurrence::InvalidConfig)
    expect { fixed(Date.new(2026, 12, 1), 0, "weeks") }.to raise_error(Recurrence::InvalidConfig)
    expect { fixed(Date.new(2026, 12, 1), 53, "weeks") }.to raise_error(Recurrence::InvalidConfig)
    expect { fixed(Date.new(2026, 12, 1), 11, "years") }.to raise_error(Recurrence::InvalidConfig)
  end

  it "is built from the task config" do
    rule = Recurrence.build(type: "fixed", config: { "anchor_on" => "2026-12-01", "interval" => 2, "unit" => "weeks" })

    expect(rule).to have_attributes(anchor_on: Date.new(2026, 12, 1), interval: 2, unit: "weeks")
  end
end
