# Recurring (config/recurring.yml): closes the occurrences past their tolerance as missed.
class MarkMissedJob < ApplicationJob
  queue_as :default

  def perform
    Tasks::MarkMissed.new.call
  end
end