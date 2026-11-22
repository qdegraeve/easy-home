module Plants
  # Rain counts as a watering (ADR 0015). Every evening, the rain of the day at the household (Weather) is recorded
  # once, then applied to the open waterings due by tomorrow of the plants placed where it rains (Location#rain_exposed):
  # heavy rain completes them (the next one starts from today), a shower postpones them by one day (Rain.effect). Plants
  # indoors or under a roof are never touched. A watering already done today stays as it is. Each change goes through
  # the usual services, under the task lock, and is undone from the journal like a manual one.
  class RecordRain
    include Dry::Monads[:result, :do]

    def call(household:, today: Time.zone.today)
      yield ensure_recordable(household, today)
      millimeters = yield fetch(household, today)

      rainfall = household.rainfalls.create!(on: today, millimeters:)
      apply(rainfall, household, today)

      Success(rainfall)
    rescue ActiveRecord::RecordNotUnique
      Failure[:already_recorded, household]
    end

    private

    def ensure_recordable(household, today)
      return Failure[:not_located, household] unless household.located?
      return Failure[:already_recorded, household] if household.rainfalls.exists?(on: today)

      Success(household)
    end

    def fetch(household, today)
      millimeters = Weather.rain.millimeters(
        latitude: household.latitude,
        longitude: household.longitude,
        date: today,
        time_zone: household.time_zone
      )
      millimeters ? Success(millimeters) : Failure[:unavailable, household]
    end

    def apply(rainfall, household, today)
      case rainfall.effect
      when :watered
        occurrences(household, today).each do |occurrence|
          Tasks::Complete.new.call(occurrence:, user: nil, source: :rain)
        end
      when :postponed
        occurrences(household, today).each do |occurrence|
          Tasks::Postpone.new.call(occurrence:, user: nil, today:, source: :rain)
        end
      end
    end

    # Open waterings due by tomorrow of the active plants placed where it rains.
    def occurrences(household, today)
      plants = household.plants.active.joins(:location).where(locations: { rain_exposed: true })
      tasks = household.tasks.active.where(template_key: Plant::WATERING_TEMPLATE_KEY, subject: plants)
      TaskOccurrence.pending.where(task: tasks, due_at: ..(today + 1).end_of_day).includes(:task).to_a
    end
  end
end
