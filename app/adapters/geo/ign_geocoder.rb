require "net/http"

module Geo
  # Autocomplétion d'adresse par le service de géocodage de l'IGN (Géoplateforme), sans clé.
  class IgnGeocoder
    ENDPOINT = URI("https://data.geopf.fr/geocodage/search")
    LIMIT = 5

    # Renvoie une liste de Geo::Suggestion, vide si le service ne répond pas.
    def suggest(query)
      uri = ENDPOINT.dup
      uri.query = URI.encode_www_form(q: query, autocomplete: 1, index: "address", limit: LIMIT)

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 3, read_timeout: 3) do |http|
        http.get(uri.request_uri)
      end
      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.warn("[Geo::IgnGeocoder] HTTP #{response.code}")
        return []
      end

      JSON.parse(response.body).fetch("features", []).map do |feature|
        longitude, latitude = feature.dig("geometry", "coordinates")
        Suggestion.new(label: feature.dig("properties", "label"), latitude:, longitude:)
      end
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError, OpenSSL::SSL::SSLError, JSON::ParserError => error
      Rails.logger.warn("[Geo::IgnGeocoder] #{error.class}: #{error.message}")
      []
    end
  end
end
