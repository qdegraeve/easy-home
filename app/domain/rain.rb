# What the rain of a day does to the waterings of the plants that get it (ADR 0015). Heavy rain waters them; a
# shower moves them one day; a drizzle changes nothing. Thresholds to refine with use.
module Rain
  WATERED_FROM = 10 # millimeters over the day
  POSTPONED_FROM = 3

  # :watered, :postponed or nil.
  def self.effect(millimeters)
    if millimeters >= WATERED_FROM
      :watered
    elsif millimeters >= POSTPONED_FROM
      :postponed
    end
  end
end
