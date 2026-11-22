require "rails_helper"

RSpec.describe Tolerance do
  def grace(importance, recurrence)
    described_class.grace_days(importance:, recurrence:)
  end

  def every(days)
    Recurrence::Sliding.new(interval_days: days)
  end

  it "gives a flexible repeating task a quarter of its interval, from 0 to 3 days" do
    expected = { 1 => 0, 2 => 1, 3 => 1, 5 => 1, 6 => 2, 7 => 2, 10 => 3, 14 => 3, 60 => 3 }

    expect(expected.keys.index_with { |days| grace(:flexible, every(days)) }).to eq(expected)
  end

  it "gives none to a task that must not be missed" do
    expect(grace(:critical, every(14))).to eq(0)
    expect(grace("critical", Recurrence::Once.new(due_on: Date.new(2026, 11, 20)))).to eq(0)
  end

  it "never misses a flexible one-off task" do
    expect(grace(:flexible, Recurrence::Once.new(due_on: Date.new(2026, 11, 20)))).to be_nil
  end

  describe ".earliest" do
    let(:today) { Date.new(2026, 11, 22) }

    it "moves a due date past the tolerance to the first day still within it" do
      expect(described_class.earliest(Time.zone.parse("2026-11-10 00:00"), grace_days: 2, today:))
        .to eq(Time.zone.parse("2026-11-20 00:00"))
      expect(described_class.earliest(Time.zone.parse("2026-11-21 00:00"), grace_days: 2, today:))
        .to eq(Time.zone.parse("2026-11-21 00:00"))
    end

    it "keeps any date of a task never missed, and no date" do
      expect(described_class.earliest(Time.zone.parse("2026-10-01 00:00"), grace_days: nil, today:))
        .to eq(Time.zone.parse("2026-10-01 00:00"))
      expect(described_class.earliest(nil, grace_days: 0, today:)).to be_nil
    end
  end
end
