require "rails_helper"

RSpec.describe Geo::OpenMeteoElevation do
  let(:endpoint) { %r{\Ahttps://api\.open-meteo\.com/v1/elevation} }

  it "returns the altitude rounded to the meter" do
    stub_request(:get, endpoint)
      .with(query: { "latitude" => "-20.88", "longitude" => "55.45" })
      .to_return(status: 200, body: { elevation: [ 34.6 ] }.to_json)

    expect(described_class.new.altitude(latitude: -20.88, longitude: 55.45)).to eq(35)
  end

  it "returns nil when the service errors" do
    stub_request(:get, endpoint).to_return(status: 429)

    expect(described_class.new.altitude(latitude: -20.88, longitude: 55.45)).to be_nil
  end

  it "returns nil when the service times out" do
    stub_request(:get, endpoint).to_timeout

    expect(described_class.new.altitude(latitude: -20.88, longitude: 55.45)).to be_nil
  end

  it "returns nil when the connection drops" do
    stub_request(:get, endpoint).to_raise(EOFError)

    expect(described_class.new.altitude(latitude: -20.88, longitude: 55.45)).to be_nil
  end

  it "returns nil on an unexpected response" do
    stub_request(:get, endpoint).to_return(status: 200, body: { elevation: nil }.to_json)

    expect(described_class.new.altitude(latitude: -20.88, longitude: 55.45)).to be_nil
  end
end
