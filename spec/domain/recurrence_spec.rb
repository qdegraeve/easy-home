require "rails_helper"

RSpec.describe Recurrence do
  describe ".build" do
    it "construit une récurrence glissante depuis une config aux clés chaîne ou symbole" do
      expect(described_class.build(type: "sliding", config: { "interval_days" => 3 }).interval_days).to eq(3)
      expect(described_class.build(type: :sliding, config: { interval_days: 4 }).interval_days).to eq(4)
    end

    it "refuse un type inconnu" do
      expect { described_class.build(type: "weekly", config: {}) }.to raise_error(Recurrence::InvalidConfig)
    end

    it "refuse une config incomplète" do
      expect { described_class.build(type: "sliding", config: {}) }.to raise_error(Recurrence::InvalidConfig)
    end
  end
end
