require "rails_helper"

RSpec.describe ReminderTime do
  it "says the time, this evening from 18:00, at its time before" do
    expect(described_class.label(19 * 60)).to eq("ce soir 19 h")
    expect(described_class.label(18 * 60)).to eq("ce soir 18 h")
    expect(described_class.label(17 * 60 + 45)).to eq("à 17 h 45")
    expect(described_class.label(7 * 60 + 30)).to eq("à 7 h 30")
  end

  it "goes to and from the field of the form" do
    expect(described_class.to_field(19 * 60)).to eq("19:00")
    expect(described_class.to_field(nil)).to be_nil
    expect(described_class.from_field("07:15")).to eq(7 * 60 + 15)
    expect(described_class.from_field("")).to be_nil
    expect(described_class.from_field("7h")).to be_nil
  end
end
