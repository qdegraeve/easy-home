module Notifications
  # Sends a user's morning digest: one push notification listing the tasks due today or late in the households the
  # user follows, to each of their phones. At most one a day (the day is claimed first, atomically), and nothing when
  # nothing is due (ADR 0012).
  class SendDigest
    include Dry::Monads[:result, :do]

    MAX_BODY_LENGTH = 240

    def call(user:, today: Time.zone.today)
      yield claim_day(user, today)
      occurrences = yield due_occurrences(user, today)
      notification(occurrences).deliver_later_to(user.push_devices.to_a)

      Success(occurrences.size)
    end

    private

    def claim_day(user, today)
      claimed = User.where(id: user.id)
        .where("last_digest_on IS NULL OR last_digest_on < ?", today)
        .update_all(last_digest_on: today)
      claimed == 1 ? Success(user) : Failure[:already_sent, user]
    end

    def due_occurrences(user, today)
      household_ids = user.household_members.where.not(role: :guest).where(digest: true).select(:household_id)
      occurrences = DueOccurrencesQuery.new.call(household_ids:, today:)
        .includes(task: :subject).order(:due_at, :id).to_a
      occurrences.any? ? Success(occurrences) : Failure[:nothing_due, user]
    end

    def notification(occurrences)
      ApplicationPushNotification
        .with_data(path: "/")
        .new(
          title: I18n.t("notifications.digest.title", count: occurrences.size),
          body: occurrences.map { |occurrence| label(occurrence.task) }.join(", ").upcase_first
            .truncate(MAX_BODY_LENGTH),
          thread_id: "digest"
        )
    end

    def label(task)
      return task.title unless task.subject
      return I18n.t("notifications.digest.watering", name: task.subject.name) if task.watering?

      I18n.t("notifications.digest.task", title: task.title, name: task.subject.name)
    end
  end
end
