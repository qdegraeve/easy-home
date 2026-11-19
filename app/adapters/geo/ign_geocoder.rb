require "net/http"

module Geo
  # Autocomplétion d'adresse par le service de géocodage de l'IGN (Géoplateforme), sans clé.
  class IgnGeocoder
    ENDPOINT = URI("https://data.geopf.fr/geocodage/search")
    LIMIT = 5

    # Renvoie une liste de Geo::Suggestion, vide si le service ne répond pas ou répond mal.
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

      features(JSON.parse(response.body)).filter_map { |feature| suggestion(feature) }
    # Service externe : toute panne (réseau, protocole, réponse inattendue) dégrade en liste vide.
    rescue StandardError => error
      Rails.logger.warn("[Geo::IgnGeocoder] #{error.class}: #{error.message}")
      []
    end

    private

    def features(json)
      json.is_a?(Hash) ? Array(json["features"]) : []
    end

    def suggestion(feature)
      label = feature.dig("properties", "label")
      longitude, latitude = feature.dig("geometry", "coordinates")
      return unless label.present? && latitude.is_a?(Numeric) && longitude.is_a?(Numeric)

      Suggestion.new(label:, latitude:, longitude:)
    end
  end
end
