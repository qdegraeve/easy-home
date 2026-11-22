require "rails_helper"

RSpec.describe MarkMissedJob do
  it "closes the occurrences past their tolerance" do
    allow(Tasks::MarkMissed).to receive(:new).and_call_original

    described_class.perform_now

    expect(Tasks::MarkMissed).to have_received(:new)
  end

  it "is scheduled every hour in production" do
    schedule = YAML.load_file(Rails.root.join("config/recurring.yml")).dig("production", "mark_missed")

    expect(schedule).to eq("class" => "MarkMissedJob", "schedule" => "every hour at minute 5")
  end
end
