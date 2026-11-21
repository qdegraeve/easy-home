module PlantAnalyzer
  # The text sent along with the photos. It describes the plant, its place and the season; the position is rounded
  # to about 1 km and the address is never sent (ADR 0008).
  class Context
    EXPOSURES = { "full_sun" => "full sun", "partial_shade" => "partial shade", "shade" => "shade" }.freeze

    def initialize(analysis, today: Time.zone.today)
      @analysis = analysis
      @plant = analysis.plant
      @today = today
    end

    def to_text
      [ plant_line, place_line, location_line, watering_line, season_line, photos_line, note_line ].compact.join("\n")
    end

    private

    attr_reader :analysis, :plant, :today

    def plant_line
      "Plant: #{plant.name}. Species on record: #{species}."
    end

    def species
      return "unknown" unless plant.species

      source = plant.species_from_user? ? "given by the owner" : "suggested by a previous analysis"
      "#{plant.species} (#{source})"
    end

    def place_line
      household = plant.household
      return "Place: Reunion Island." unless household.located?

      altitude = household.altitude_m ? ", altitude #{household.altitude_m} m" : ""
      "Place: Reunion Island, around #{household.latitude.round(2)}, #{household.longitude.round(2)}#{altitude}."
    end

    # The conditions recorded when the analysis was requested (PlantAnalysis#place): the ones the advice is compared
    # with later, even if the location changes while the analysis runs. Older analyses read the plant's location.
    def location_line
      place = analysis.place || plant.place
      return unless place["exposure"]

      wind = place["sheltered"] ? "sheltered from the wind" : "exposed to the wind"
      spot = [ plant.location&.name, EXPOSURES.fetch(place["exposure"]) ].compact.join(", ")
      "Spot: #{spot}, #{wind}."
    end

    def watering_line
      interval = plant.watering_task&.recurrence&.interval_days
      "Current watering: every #{interval} days." if interval
    end

    def season_line
      "Today: #{today.iso8601} (#{Date::MONTHNAMES[today.month]}, southern hemisphere)."
    end

    def photos_line
      dates = analysis.photos_oldest_first.each_with_index.map do |photo, index|
        "photo #{index + 1} on #{photo.taken_at.to_date.iso8601}"
      end
      "Photos, oldest first: #{dates.join(", ")}."
    end

    def note_line
      "Note from the owner: #{analysis.user_note}" if analysis.user_note.present?
    end
  end
end
