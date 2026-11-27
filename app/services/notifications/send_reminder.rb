module Notifications
  # Sends the reminder of an occurrence due (ADR 0017), or its follow-up: one push notification to each phone of the
  # members who follow its household (HouseholdMember#digest), and of its guests to whom the task is opened, even
  # with their morning digest turned off: the reminder was set on purpose on the task. The send is claimed first, atomically, with the conditions of
  # RemindersDueQuery checked again at that moment: two runs never send it twice, and a task moved, done or stopped in
  # between is not reminded. Claimed before delivery: at most one attempt per send, like the morning digest. A
  # follow-up replaces the previous notification on the phone (thread per task). The notification names the task (and
  # its plant or equipment), never its instructions, and opens its sheet.
  class SendReminder
    include Dry::Monads[:result, :do]

    def call(occurrence:, now: Time.current, devices: nil)
      sent_before = yield claim(occurrence, now)
      devices ||= self.class.recipients(occurrence.task)
      notification(occurrence.task, follow_up: sent_before.positive?).deliver_later_to(devices) if devices.any?

      Success(devices.size)
    end

    # The phones of the members who follow the household, and of its guests to whom the task is opened today
    # (ADR 0019). member_devices: those of the members, already looked up for the household.
    def self.recipients(task, member_devices: nil)
      (member_devices || self.member_devices(task.household_id)) + guest_devices(task)
    end

    def self.member_devices(household_id)
      followers = HouseholdMember.where(household_id:, digest: true).where.not(role: :guest).select(:user_id)
      ApplicationPushDevice.where(owner: Session.where(user_id: followers)).to_a
    end

    def self.guest_devices(task)
      guests = HouseholdMember.guests_on(Time.zone.today).joined.where(household_id: task.household_id, digest: true)
      user_ids = guests.includes(:user)
        .select { |guest| GuestVisibilityQuery.new(guest.user).tasks.exists?(task.id) }.map(&:user_id)
      return [] if user_ids.empty?

      ApplicationPushDevice.where(owner: Session.where(user_id: user_ids)).to_a
    end

    private

    # [reminders sent before this one]
    def claim(occurrence, now)
      sent_before = RemindersDueQuery.sent(occurrence.id).to_i
      claimed = RemindersDueQuery.new(TaskOccurrence.where(id: occurrence.id)).call(now:, sent: sent_before)
        .update_all(reminders_sent: sent_before + 1, last_reminded_at: now)
      claimed == 1 ? Success(sent_before) : Failure[:already_sent, occurrence]
    end

    def notification(task, follow_up:)
      ApplicationPushNotification
        .with_data(path: Rails.application.routes.url_helpers.task_path(task))
        .new(title: title(task, follow_up), body: nil, thread_id: "task-#{task.id}")
    end

    # "Sortir la poubelle jaune", "Tailler · Citronnier"; a follow-up: "Toujours à faire : sortir la poubelle jaune".
    def title(task, follow_up)
      name = task.title
      name = I18n.t("notifications.reminder.with_subject", title: name, name: task.subject.name) if task.subject
      follow_up ? I18n.t("notifications.reminder.follow_up", what: name.downcase_first) : name
    end
  end
end
