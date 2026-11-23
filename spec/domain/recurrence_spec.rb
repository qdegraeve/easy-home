require "rails_helper"

RSpec.describe Recurrence do
  describe ".build" do
    it "builds a sliding recurrence from a config with string or symbol keys" do
      config = { "interval" => 3, "unit" => "days" }
      expect(described_class.build(type: "sliding", config:).interval_days).to eq(3)
      expect(described_class.build(type: :sliding, config: { interval: 4, unit: "days" }).interval_days).to eq(4)
    end

    it "builds a one-off recurrence and a start date from ISO 8601 dates" do
      once = described_class.build(type: "once", config: { "due_on" => "2026-11-30" })
      expect(once.due_on).to eq(Date.new(2026, 11, 30))
      config = { "interval" => 14, "unit" => "days", "start_on" => "2026-12-01" }
      sliding = described_class.build(type: "sliding", config:)
      expect(sliding.start_on).to eq(Date.new(2026, 12, 1))
    end

    it "rejects an unreadable date" do
      expect { described_class.build(type: "once", config: { "due_on" => "2026-02-30" }) }
        .to raise_error(Recurrence::InvalidConfig)
      expect { described_class.build(type: "once", config: { "due_on" => 20261130 }) }
        .to raise_error(Recurrence::InvalidConfig)
    end

    it "rejects an unknown type" do
      expect { described_class.build(type: "weekly", config: {}) }.to raise_error(Recurrence::InvalidConfig)
    end

    it "rejects an incomplete config" do
      expect { described_class.build(type: "sliding", config: {}) }.to raise_error(Recurrence::InvalidConfig)
    end
  end

  it "still reads the former config of a sliding task (interval_days), for a deploy or rollback around it" do
    rule = described_class.build(type: "sliding", config: { "interval_days" => 5, "start_on" => "2026-12-01" })

    expect(rule).to have_attributes(interval: 5, unit: "days", start_on: Date.new(2026, 12, 1))
  end
end
