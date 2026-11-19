require "rails_helper"

RSpec.describe Geo::OpenMeteoElevation do
  let(:endpoint) { %r{\Ahttps://api\.open-meteo\.com/v1/elevation} }

  it "renvoie l'altitude arrondie au mètre" do
    stub_request(:get, endpoint)
      .with(query: { "latitude" => "-20.88", "longitude" => "55.45" })
      .to_return(status: 200, body: { elevation: [ 34.6 ] }.to_json)

    expect(described_class.new.altitude(latitude: -20.88, longitude: 55.45)).to eq(35)
  end

  it "renvoie nil quand le service est en erreur" do
    stub_request(:get, endpoint).to_return(status: 429)

    expect(described_class.new.altitude(latitude: -20.88, longitude: 55.45)).to be_nil
  end

  it "renvoie nil quand le service ne répond pas" do
    stub_request(:get, endpoint).to_timeout

    expect(described_class.new.altitude(latitude: -20.88, longitude: 55.45)).to be_nil
  end

  it "renvoie nil quand la connexion est coupée" do
    stub_request(:get, endpoint).to_raise(EOFError)

    expect(described_class.new.altitude(latitude: -20.88, longitude: 55.45)).to be_nil
  end

  it "renvoie nil sur une réponse inattendue" do
    stub_request(:get, endpoint).to_return(status: 200, body: { elevation: nil }.to_json)

    expect(described_class.new.altitude(latitude: -20.88, longitude: 55.45)).to be_nil
  end
end
