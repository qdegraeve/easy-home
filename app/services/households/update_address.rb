module Households
  # Enregistre l'adresse choisie dans l'autocomplétion. L'altitude est recalculée quand la position change ;
  # sinon l'altitude saisie à la main est conservée.
  class UpdateAddress
    include Dry::Monads[:result]

    def call(household:, params:)
      household.assign_attributes(
        address: params[:address].presence,
        latitude: params[:latitude].presence,
        longitude: params[:longitude].presence,
        altitude_m: params[:altitude_m].presence
      )
      household.assign_attributes(latitude: nil, longitude: nil, altitude_m: nil) if household.address.nil?
      household.altitude_m = fetch_altitude(household) if household.located? && position_changed?(household)

      household.save ? Success(household) : Failure[:invalid, household]
    end

    private

    def position_changed?(household)
      household.latitude_changed? || household.longitude_changed?
    end

    def fetch_altitude(household)
      Geo.elevation.altitude(latitude: household.latitude, longitude: household.longitude)
    end
  end
end
