module Plants
  # Sets the watering interval proposed by an AI analysis on the plant's watering task, then reschedules its open
  # occurrence from the last watering (ADR 0008).
  class AcceptWatering
    include Dry::Monads[:result, :do]

    def call(analysis:)
      yield check_proposal(analysis)
      update_watering(analysis.plant.watering_task, analysis.watering_interval_days)
    end

    private

    def check_proposal(analysis)
      return Failure[:not_acceptable, analysis] unless analysis.done? && analysis.watering_interval_days
      return Failure[:not_acceptable, analysis] unless analysis.plant.watering_task
      return Failure[:subject_archived, analysis] if analysis.plant.archived?

      Success(analysis)
    end

    def update_watering(task, interval_days)
      ActiveRecord::Base.transaction do
        task.lock!
        task.update!(recurrence_config: task.recurrence_config.merge("interval" => interval_days, "unit" => "days"))
        Tasks::Reschedule.new.call(task:)
      end
      Success(task)
    end
  end
end
