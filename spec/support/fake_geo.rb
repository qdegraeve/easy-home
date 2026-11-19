# Fake geographic adapters, injected by default in every spec (ADR 0009).
class FakeGeocoder
  ADDRESSES = [
    Geo::Suggestion.new(label: "12 Rue des Exemples 97400 Ville-Exemple", latitude: -20.9, longitude: 55.45),
    Geo::Suggestion.new(label: "12 Chemin des Exemples 97460 Autre-Exemple", latitude: -21.0, longitude: 55.3)
  ].freeze

  def suggest(query)
    words = query.downcase.split
    ADDRESSES.select { |suggestion| words.all? { |word| suggestion.label.downcase.include?(word) } }
  end
end

class FakeElevation
  attr_accessor :result

  def initialize(result: 320)
    @result = result
  end

  def altitude(latitude:, longitude:)
    result
  end
end

RSpec.configure do |config|
  config.before do
    Geo.geocoder = FakeGeocoder.new
    Geo.elevation = FakeElevation.new
  end

  config.after do
    Geo.geocoder = nil
    Geo.elevation = nil
  end
end
