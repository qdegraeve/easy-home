require "rails_helper"

RSpec.describe Recurrence do
  describe ".build" do
    it "builds a sliding recurrence from a config with string or symbol keys" do
      expect(described_class.build(type: "sliding", config: { "interval_days" => 3 }).interval_days).to eq(3)
      expect(described_class.build(type: :sliding, config: { interval_days: 4 }).interval_days).to eq(4)
    end

    it "builds a one-off recurrence and a start date from ISO 8601 dates" do
      once = described_class.build(type: "once", config: { "due_on" => "2026-11-30" })
      expect(once.due_on).to eq(Date.new(2026, 11, 30))
      sliding = described_class.build(type: "sliding", config: { "interval_days" => 14, "start_on" => "2026-12-01" })
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
end
