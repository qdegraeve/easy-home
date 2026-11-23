module Notifications
  # Sends the reminder of an occurrence due (ADR 0017), or its follow-up: one push notification to each phone of the
  # members who follow its household (HouseholdMember#digest), even with their morning digest turned off: the
  # reminder was set on purpose on the task. The send is claimed first, atomically: two runs at the same moment never
  # send it twice. A follow-up replaces the previous notification on the phone (thread per task). The notification
  # names the task (and its plant or equipment), never its instructions, and opens its sheet.
  class SendReminder
    include Dry::Monads[:result, :do]

    def call(occurrence:, now: Time.current)
      sent_before = occurrence.reminders_sent
      yield claim(occurrence, sent_before, now)
      devices = recipients(occurrence.task.household_id)
      notification(occurrence.task, follow_up: sent_before.positive?).deliver_later_to(devices) if devices.any?

      Success(devices.size)
    end

    private

    def claim(occurrence, sent_before, now)
      claimed = TaskOccurrence.pending.where(id: occurrence.id, reminders_sent: sent_before)
        .update_all(reminders_sent: sent_before + 1, last_reminded_at: now)
      claimed == 1 ? Success(occurrence) : Failure[:already_sent, occurrence]
    end

    def recipients(household_id)
      followers = HouseholdMember.where(household_id:, digest: true).where.not(role: :guest).select(:user_id)
      ApplicationPushDevice.where(owner_type: "Session", owner_id: Session.where(user_id: followers).select(:id)).to_a
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
