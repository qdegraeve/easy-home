# External geographic services (ADR 0009). Replaced by fake adapters in tests.
module Geo
  Suggestion = Data.define(:label, :latitude, :longitude)

  class << self
    attr_writer :geocoder, :elevation

    def geocoder
      @geocoder ||= IgnGeocoder.new
    end

    def elevation
      @elevation ||= OpenMeteoElevation.new
    end
  end
end
