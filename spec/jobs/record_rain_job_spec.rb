require "rails_helper"

RSpec.describe RecordRainJob do
  it "records the rain of each household with an address" do
    located = create(:household, :located)
    create(:household)
    Weather.rain.result = 4

    described_class.perform_now

    expect(Rainfall.pluck(:household_id)).to eq([ located.id ])
  end

  it "is scheduled every evening at 10 pm, Reunion time, in production" do
    schedule = YAML.load_file(Rails.root.join("config/recurring.yml")).dig("production", "record_rain")

    expect(schedule).to eq("class" => "RecordRainJob", "schedule" => "every day at 10pm Indian/Reunion")
  end
end
