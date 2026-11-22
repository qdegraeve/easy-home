require "net/http"

module Weather
  # Rain of a day at a point through the Open-Meteo forecast API (free for non-commercial use, no key, ADR 0009):
  # the daily sum, measured for the hours past and forecast for the ones left.
  class OpenMeteoRain
    ENDPOINT = URI("https://api.open-meteo.com/v1/forecast")

    # Millimeters (Float) fallen on the date, in the time zone; nil when the service is down or answers badly.
    def millimeters(latitude:, longitude:, date:, time_zone:)
      uri = ENDPOINT.dup
      uri.query = URI.encode_www_form(
        latitude:,
        longitude:,
        daily: "precipitation_sum",
        timezone: time_zone,
        start_date: date.iso8601,
        end_date: date.iso8601
      )

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 3, read_timeout: 5) do |http|
        http.get(uri.request_uri)
      end
      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.warn("[Weather::OpenMeteoRain] HTTP #{response.code}")
        return
      end

      json = JSON.parse(response.body)
      value = Array(json.is_a?(Hash) ? json.dig("daily", "precipitation_sum") : nil).first
      value.to_f if value.is_a?(Numeric)
    # External service: any failure (network, protocol, unexpected response) degrades to an unknown rain.
    rescue StandardError => error
      Rails.logger.warn("[Weather::OpenMeteoRain] #{error.class}: #{error.message}")
      nil
    end
  end
end
