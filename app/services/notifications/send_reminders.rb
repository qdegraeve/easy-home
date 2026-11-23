module Notifications
  # Sends the reminders and follow-ups due now (RemindersDueQuery). Run every 5 minutes by SendRemindersJob, so a
  # reminder leaves within minutes of its time. The phones are looked up once per household.
  class SendReminders
    include Dry::Monads[:result]

    def call(now: Time.current)
      occurrences = RemindersDueQuery.new.call(now:).includes(task: :subject).to_a
      devices = Hash.new { |cache, household_id| cache[household_id] = SendReminder.recipients(household_id) }

      sent = occurrences.count do |occurrence|
        SendReminder.new.call(occurrence:, now:, devices: devices[occurrence.task.household_id]).success?
      end
      Success(sent)
    end
  end
end
