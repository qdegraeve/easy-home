require "rails_helper"

RSpec.describe Rain do
  {
    0 => nil,
    2.9 => nil,
    3 => :postponed,
    9.9 => :postponed,
    10 => :watered,
    48 => :watered
  }.each do |millimeters, effect|
    it "gives #{effect.inspect} for #{millimeters} mm" do
      expect(described_class.effect(millimeters)).to eq(effect)
    end
  end
end
