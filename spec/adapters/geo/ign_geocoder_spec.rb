require "rails_helper"

RSpec.describe Geo::IgnGeocoder do
  let(:endpoint) { %r{\Ahttps://data\.geopf\.fr/geocodage/search} }

  it "renvoie les adresses proposées avec leur position" do
    body = {
      features: [
        { properties: { label: "1 Rue Exemple 97400 Ville" }, geometry: { coordinates: [ 55.45, -20.88 ] } }
      ]
    }
    stub = stub_request(:get, endpoint)
      .with(query: hash_including("q" => "1 rue exemple", "autocomplete" => "1", "index" => "address"))
      .to_return(status: 200, body: body.to_json)

    suggestions = described_class.new.suggest("1 rue exemple")

    expect(stub).to have_been_requested
    expect(suggestions).to eq([ Geo::Suggestion.new(label: "1 Rue Exemple 97400 Ville", latitude: -20.88, longitude: 55.45) ])
  end

  it "renvoie une liste vide quand le service est en erreur" do
    stub_request(:get, endpoint).to_return(status: 503)

    expect(described_class.new.suggest("1 rue exemple")).to eq([])
  end

  it "renvoie une liste vide quand le service ne répond pas" do
    stub_request(:get, endpoint).to_timeout

    expect(described_class.new.suggest("1 rue exemple")).to eq([])
  end

  it "renvoie une liste vide quand la connexion est coupée" do
    stub_request(:get, endpoint).to_raise(EOFError)

    expect(described_class.new.suggest("1 rue exemple")).to eq([])
  end

  it "renvoie une liste vide sur une réponse inattendue" do
    stub_request(:get, endpoint).to_return(status: 200, body: { features: nil }.to_json)

    expect(described_class.new.suggest("1 rue exemple")).to eq([])
  end

  it "écarte les suggestions sans libellé ou sans position" do
    body = {
      features: [
        { properties: { label: "Sans position" }, geometry: nil },
        { properties: {}, geometry: { coordinates: [ 55.45, -20.88 ] } },
        { properties: { label: "Complète" }, geometry: { coordinates: [ 55.45, -20.88 ] } }
      ]
    }
    stub_request(:get, endpoint).to_return(status: 200, body: body.to_json)

    expect(described_class.new.suggest("1 rue exemple").map(&:label)).to eq([ "Complète" ])
  end
end
