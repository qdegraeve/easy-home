# External weather service (ADR 0015). Replaced by a fake adapter in tests.
module Weather
  class << self
    attr_writer :rain

    def rain
      @rain ||= OpenMeteoRain.new
    end
  end
end
