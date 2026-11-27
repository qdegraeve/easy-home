module Notifications
  # Sends the reminders and follow-ups due now (RemindersDueQuery). Run every 5 minutes by SendRemindersJob, so a
  # reminder leaves within minutes of its time. The members' phones are looked up once per household.
  class SendReminders
    include Dry::Monads[:result]

    def call(now: Time.current)
      occurrences = RemindersDueQuery.new.call(now:).includes(task: :subject).to_a
      members = Hash.new { |cache, household_id| cache[household_id] = SendReminder.member_devices(household_id) }

      sent = occurrences.count do |occurrence|
        task = occurrence.task
        devices = SendReminder.recipients(task, member_devices: members[task.household_id])
        SendReminder.new.call(occurrence:, now:, devices:).success?
      end
      Success(sent)
    end
  end
end
