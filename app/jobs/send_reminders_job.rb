# Recurring (config/recurring.yml): sends the reminders at a time and their follow-ups that are due (ADR 0017).
class SendRemindersJob < ApplicationJob
  queue_as :default

  def perform
    Notifications::SendReminders.new.call
  end
end
