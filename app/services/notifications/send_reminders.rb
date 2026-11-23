module Notifications
  # Sends the reminders and follow-ups due now (RemindersDueQuery). Run every 5 minutes by SendRemindersJob, so a
  # reminder leaves within minutes of its time.
  class SendReminders
    include Dry::Monads[:result]

    def call(now: Time.current)
      occurrences = RemindersDueQuery.new.call(now:).includes(task: :subject)

      Success(occurrences.count { |occurrence| SendReminder.new.call(occurrence:, now:).success? })
    end
  end
end
