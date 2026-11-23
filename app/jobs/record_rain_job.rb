# Recurring (config/recurring.yml), every evening: the rain of the day waters or postpones the waterings of the plants
# outside (Plants::RecordRain), for each household with an address.
class RecordRainJob < ApplicationJob
  queue_as :default

  def perform
    Household.where.not(latitude: nil).where.not(longitude: nil).find_each do |household|
      Plants::RecordRain.new.call(household:)
    # One household in error must not deprive the others of the rain; it is reported and caught up by the next run.
    rescue StandardError => error
      Rails.error.report(error, context: { household_id: household.id })
    end
  end
end
