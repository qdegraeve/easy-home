module Plants
  # Rain counts as a watering (ADR 0015). Every evening, the rain of the day at the household (Weather) is recorded
  # once, then applied to the open waterings due by tomorrow of the plants placed where it rains
  # (Location#rain_exposed): heavy rain completes them (the next one starts from today), a shower postpones them by one
  # day (Rain.effect). Plants indoors or under a roof are never touched, nor a watering done today. Each change goes
  # through the usual services, under the task lock, and is undone from the journal like a manual one.
  #
  # The rule is applied again until it went through (Rainfall#applied_at): a restart in the middle is caught up by the
  # next run, and the tasks already closed by the rain that day are skipped. "Today" is the day of the application time
  # zone, like every task; the weather service is asked in the household's time zone, the same one for now.
  class RecordRain
    include Dry::Monads[:result, :do]

    def call(household:, today: Time.zone.today)
      return Failure[:not_located, household] unless household.located?

      rainfall = household.rainfalls.find_by(fell_on: today) || yield(record(household, today))
      return Failure[:already_recorded, household] if rainfall.applied_at

      apply(rainfall, household, today)
      rainfall.update!(applied_at: Time.current)

      Success(rainfall)
    end

    private

    def record(household, today)
      millimeters = Weather.rain.millimeters(
        latitude: household.latitude,
        longitude: household.longitude,
        date: today,
        time_zone: household.time_zone
      )
      return Failure[:unavailable, household] unless millimeters

      Success(household.rainfalls.create!(fell_on: today, millimeters:))
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      Failure[:already_recorded, household] # another run recorded it at the same moment
    end

    def apply(rainfall, household, today)
      effect = rainfall.effect
      return unless effect

      occurrences(household, today).each do |occurrence|
        result = if effect == :watered
          Tasks::Complete.new.call(occurrence:, user: nil, source: :rain)
        else
          Tasks::Postpone.new.call(occurrence:, user: nil, today:, source: :rain)
        end
        log_failure(result, occurrence) if result.failure?
      end
    end

    # Open waterings due by tomorrow of the active plants placed where it rains, but for the tasks done today (the
    # plant got its water) or already closed by the rain today (a run caught up after a restart).
    def occurrences(household, today)
      plants = household.plants.active.joins(:location).where(locations: { rain_exposed: true })
      tasks = household.tasks.active.where(template_key: Plant::WATERING_TEMPLATE_KEY, subject: plants)
      closed_today = TaskOccurrence.where(completed_at: today.all_day)
        .where(status: :done).or(TaskOccurrence.where(completed_at: today.all_day, source: :rain))
      TaskOccurrence.pending.where(task: tasks, due_at: ..(today + 1).end_of_day)
        .where.not(task_id: closed_today.select(:task_id)).includes(:task).to_a
    end

    def log_failure(result, occurrence)
      Rails.logger.info("[Plants::RecordRain] occurrence #{occurrence.id} left as is: #{result.failure.first}")
    end
  end
end
