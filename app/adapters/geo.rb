# Services géographiques externes (ADR 0009). Remplaçables en test par de faux adaptateurs.
module Geo
  Suggestion = Data.define(:label, :latitude, :longitude)

  class << self
    attr_writer :geocoder, :elevation

    def geocoder = @geocoder ||= IgnGeocoder.new

    def elevation = @elevation ||= OpenMeteoElevation.new
  end
end
