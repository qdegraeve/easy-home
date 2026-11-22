require "rails_helper"
require "fugit"

RSpec.describe RecordRainJob do
  it "records the rain of each household with an address" do
    located = create(:household, :located)
    create(:household)
    Weather.rain.result = 4

    described_class.perform_now

    expect(Rainfall.pluck(:household_id)).to eq([ located.id ])
  end

  it "goes on with the next households when one fails" do
    failing, next_one = create(:household, :located), create(:household, :located)
    allow(Plants::RecordRain).to receive(:new).and_wrap_original do |original|
      service = original.call
      allow(service).to receive(:call).and_wrap_original do |call, household:|
        raise ActiveRecord::ConnectionTimeoutError, "boom" if household == failing

        call.call(household:)
      end
      service
    end
    allow(Rails.error).to receive(:report)

    described_class.perform_now

    expect(Rails.error).to have_received(:report).with(kind_of(ActiveRecord::ConnectionTimeoutError),
                                                       context: { household_id: failing.id })
    expect(Rainfall.pluck(:household_id)).to eq([ next_one.id ])
  end

  it "is scheduled every evening at 10 pm, Reunion time, in production" do
    schedule = YAML.load_file(Rails.root.join("config/recurring.yml")).dig("production", "record_rain")

    expect(schedule).to eq("class" => "RecordRainJob", "schedule" => "every day at 10pm Indian/Reunion")
    expect(Fugit.parse_cronish(schedule["schedule"]).to_cron_s).to eq("0 22 * * * Indian/Reunion")
  end
end
