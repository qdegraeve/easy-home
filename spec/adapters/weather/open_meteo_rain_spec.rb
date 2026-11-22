require "rails_helper"

RSpec.describe Weather::OpenMeteoRain do
  let(:endpoint) { %r{\Ahttps://api\.open-meteo\.com/v1/forecast} }
  let(:arguments) { { latitude: -20.9, longitude: 55.45, date: Date.new(2026, 11, 16), time_zone: "Indian/Reunion" } }

  it "returns the rain of the day, in the household's time zone" do
    stub_request(:get, endpoint)
      .with(query: {
        "latitude" => "-20.9",
        "longitude" => "55.45",
        "daily" => "precipitation_sum",
        "timezone" => "Indian/Reunion",
        "start_date" => "2026-11-16",
        "end_date" => "2026-11-16"
      })
      .to_return(status: 200, body: { daily: { time: [ "2026-11-16" ], precipitation_sum: [ 14.2 ] } }.to_json)

    expect(described_class.new.millimeters(**arguments)).to eq(14.2)
  end

  it "returns nil when the service errors" do
    stub_request(:get, endpoint).to_return(status: 500)

    expect(described_class.new.millimeters(**arguments)).to be_nil
  end

  it "returns nil when the service times out" do
    stub_request(:get, endpoint).to_timeout

    expect(described_class.new.millimeters(**arguments)).to be_nil
  end

  it "returns nil on an unexpected response" do
    stub_request(:get, endpoint).to_return(status: 200, body: { daily: { precipitation_sum: [ nil ] } }.to_json)
    expect(described_class.new.millimeters(**arguments)).to be_nil

    stub_request(:get, endpoint).to_return(status: 200, body: [ 1 ].to_json)
    expect(described_class.new.millimeters(**arguments)).to be_nil
  end
end
