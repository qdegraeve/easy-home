require "rails_helper"

RSpec.describe Recurrence::Once do
  let(:zone) { ActiveSupport::TimeZone["Indian/Reunion"] }

  it "falls on the planned day, at the start of the local day, while not done" do
    due = described_class.new(due_on: Date.new(2026, 11, 30)).next_due_at(last_completed_at: nil)

    expect(due).to eq(zone.parse("2026-11-30 00:00"))
    expect(due.utc).to eq(Time.utc(2026, 11, 29, 20, 0))
  end

  it "has no occurrence left once done, even early or late" do
    recurrence = described_class.new(due_on: Date.new(2026, 11, 30))

    expect(recurrence.next_due_at(last_completed_at: zone.parse("2026-11-20 10:00"))).to be_nil
    expect(recurrence.next_due_at(last_completed_at: zone.parse("2026-12-05 10:00"))).to be_nil
  end

  it "accepts a past date (task late from its creation)" do
    expect(described_class.new(due_on: Date.new(2020, 2, 29)).next_due_at(last_completed_at: nil))
      .to eq(zone.parse("2020-02-29 00:00"))
  end

  [ nil, "2026-11-30", Time.current ].each do |value|
    it "rejects due_on = #{value.inspect}" do
      expect { described_class.new(due_on: value) }.to raise_error(Recurrence::InvalidConfig)
    end
  end
end
