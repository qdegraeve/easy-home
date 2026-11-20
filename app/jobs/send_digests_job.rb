# Recurring (config/recurring.yml): sends the morning digests that are due.
class SendDigestsJob < ApplicationJob
  queue_as :default

  def perform
    Notifications::SendDigests.new.call
  end
end
