module Notifications
  # Sends a user's morning digest: one push notification listing the tasks due today or late in the households the
  # user follows, to each of their phones. At most one a day (the day is claimed first, atomically), and nothing when
  # nothing is due (ADR 0012). Grouped like the screen (UX review #21): the tasks that must not be missed first, then
  # all the waterings in one item ("arroser 4 plantes"), then the other tasks. With the "critical" scope, only the
  # tasks that must not be missed (#22).
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

    # The followed households; a guest's digest lists only the tasks opened to them, during their period (ADR 0019):
    # what the policies let the user see.
    def due_occurrences(user, today)
      household_ids = user.household_members.where(digest: true).select(:household_id)
      visible = TaskOccurrencePolicy::Scope.new(user, TaskOccurrence).resolve
      occurrences = DueOccurrencesQuery.new(visible).call(household_ids:, today:)
        .includes(task: :subject).order(:due_at, :id).to_a
      occurrences.select! { |occurrence| occurrence.task.critical? } if user.digest_critical?
      occurrences.any? ? Success(occurrences) : Failure[:nothing_due, user]
    end

    def notification(occurrences)
      ApplicationPushNotification
        .with_data(path: "/")
        .new(
          title: I18n.t("notifications.digest.title", count: occurrences.size),
          body: items(occurrences).join(", ").upcase_first.truncate(MAX_BODY_LENGTH),
          thread_id: "digest"
        )
    end

    # In the order of the screen (TaskListComponent): the waterings are grouped first, then the critical tasks lead.
    def items(occurrences)
      waterings, others = occurrences.partition { |occurrence| occurrence.task.watering? }
      critical, others = others.partition { |occurrence| occurrence.task.critical? }
      critical.map { |occurrence| label(occurrence) } + watering_items(waterings) +
        others.map { |occurrence| label(occurrence) }
    end

    def watering_items(waterings)
      return waterings.map { |occurrence| label(occurrence) } if waterings.size < 2

      [ I18n.t("notifications.digest.waterings", count: waterings.size) ]
    end

    # "Pailler le pied (Citronnier)"; a task due today with a reminder still to come says when: "ce soir 19 h :
    # sortir la poubelle jaune" (a late one, or one whose time has passed, is not announced).
    def label(occurrence)
      task = occurrence.task
      what = what(task)
      return what unless reminder_to_come?(occurrence)

      I18n.t("notifications.digest.at_time", when: ReminderTime.label(task.reminder_minute), what: what.downcase_first)
    end

    def reminder_to_come?(occurrence)
      minute = occurrence.task.reminder_minute
      now = Time.current
      minute && occurrence.due_at.to_date == now.to_date && minute > (now.hour * 60) + now.min
    end

    def what(task)
      return task.title unless task.subject
      return I18n.t("notifications.digest.watering", name: task.subject.name) if task.watering?

      I18n.t("notifications.digest.task", title: task.title, name: task.subject.name)
    end
  end
end
