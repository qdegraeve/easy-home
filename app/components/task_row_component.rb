# One open task in a list (UX review, "Ligne de tâche"): domain mark, what to do, when it is due, and a round "done"
# button of 44 px, empty until pressed (an action, not a state). Once done today, the button gives way to a calm
# "done today" label. With postpone, a due or late task also offers a "Reporter" pill (Tasks::Postpone), rather than
# staying late.
#
#   render TaskRowComponent.new(occurrence:, title: "Citronnier", href: plant_path(plant), detail: "Arrosage")
#   => Citronnier / Arrosage · demain
class TaskRowComponent < ViewComponent::Base
  renders_one :actions

  def initialize(occurrence:, title:, detail:, href: nil, done_today: false, postpone: false)
    @occurrence = occurrence
    @task = occurrence.task
    @title = title
    @detail = detail
    @href = href
    @done_today = done_today
    @postpone = postpone
  end

  private

  attr_reader :occurrence, :task, :title, :detail, :href, :done_today

  def postpone?
    @postpone && !done_today && occurrence.due_at.to_date <= Time.zone.today
  end

  # "Reporter à demain : Tailler (Citronnier)".
  def postpone_label
    return t(".postpone", title: task.title) unless task.subject

    t(".postpone_with_subject", title: task.title, subject: task.subject.name)
  end

  def mark_icon
    return :droplet if task.watering?

    task.critical? ? :triangle_alert : :list_todo
  end

  # Button name for screen readers, an action: "Marquer comme arrosée : Citronnier", "Marquer comme fait : Tailler
  # (Citronnier)".
  def done_label
    return t(".done_watering", name: task.subject.name) if task.watering?
    return t(".done_with_subject", title: task.title, subject: task.subject.name) if task.subject

    t(".done", title: task.title)
  end

  def done_today_label
    task.watering? ? t(".watered_today") : t(".done_today")
  end
end
