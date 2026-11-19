require "rails_helper"

RSpec.describe Recurrence do
  describe ".build" do
    it "construit une récurrence glissante depuis une config aux clés chaîne ou symbole" do
      expect(described_class.build(type: "sliding", config: { "interval_days" => 3 }).interval_days).to eq(3)
      expect(described_class.build(type: :sliding, config: { interval_days: 4 }).interval_days).to eq(4)
    end

    it "construit une récurrence unique et une date de début depuis des dates ISO 8601" do
      once = described_class.build(type: "once", config: { "due_on" => "2026-11-30" })
      expect(once.due_on).to eq(Date.new(2026, 11, 30))
      sliding = described_class.build(type: "sliding", config: { "interval_days" => 14, "start_on" => "2026-12-01" })
      expect(sliding.start_on).to eq(Date.new(2026, 12, 1))
    end

    it "refuse une date illisible" do
      expect { described_class.build(type: "once", config: { "due_on" => "2026-02-30" }) }
        .to raise_error(Recurrence::InvalidConfig)
      expect { described_class.build(type: "once", config: { "due_on" => 20261130 }) }
        .to raise_error(Recurrence::InvalidConfig)
    end

    it "refuse un type inconnu" do
      expect { described_class.build(type: "weekly", config: {}) }.to raise_error(Recurrence::InvalidConfig)
    end

    it "refuse une config incomplète" do
      expect { described_class.build(type: "sliding", config: {}) }.to raise_error(Recurrence::InvalidConfig)
    end
  end
end
