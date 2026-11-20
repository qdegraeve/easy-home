require "rails_helper"

RSpec.describe SendDigestsJob do
  it "runs the digests of the moment" do
    allow(Notifications::SendDigests).to receive(:new).and_call_original

    described_class.perform_now

    expect(Notifications::SendDigests).to have_received(:new)
  end

  it "is scheduled every few minutes in production" do
    schedule = YAML.load_file(Rails.root.join("config/recurring.yml")).dig("production", "send_digests")

    expect(schedule).to eq("class" => "SendDigestsJob", "schedule" => "every 5 minutes")
  end
end
