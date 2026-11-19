require "net/http"

module Geo
  # Altitude of a point through the Open-Meteo elevation API (free for non-commercial use, no key).
  class OpenMeteoElevation
    ENDPOINT = URI("https://api.open-meteo.com/v1/elevation")

    # Altitude in meters (integer), nil when the service is down or answers badly.
    def altitude(latitude:, longitude:)
      uri = ENDPOINT.dup
      uri.query = URI.encode_www_form(latitude:, longitude:)

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 3, read_timeout: 3) do |http|
        http.get(uri.request_uri)
      end
      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.warn("[Geo::OpenMeteoElevation] HTTP #{response.code}")
        return
      end

      json = JSON.parse(response.body)
      value = Array(json.is_a?(Hash) ? json["elevation"] : nil).first
      value.round if value.is_a?(Numeric)
    # External service: any failure (network, protocol, unexpected response) degrades to an unknown altitude.
    rescue StandardError => error
      Rails.logger.warn("[Geo::OpenMeteoElevation] #{error.class}: #{error.message}")
      nil
    end
  end
end
