# One open task in a list (UX review, "Ligne de tâche"): domain mark, what to do, when it is due, and a round "done"
# button of 44 px. Once done today, the button gives way to a calm "done today" label.
#
#   render TaskRowComponent.new(occurrence:, title: "Citronnier", href: plant_path(plant), detail: "Arrosage")
#   => Citronnier / Arrosage · demain
class TaskRowComponent < ViewComponent::Base
  renders_one :actions

  def initialize(occurrence:, title:, detail:, href: nil, done_today: false)
    @occurrence = occurrence
    @task = occurrence.task
    @title = title
    @detail = detail
    @href = href
    @done_today = done_today
  end

  private

  attr_reader :occurrence, :task, :title, :detail, :href, :done_today

  def mark_icon
    task.watering? ? :droplet : :list_todo
  end

  # Button name for screen readers: "Arrosée : Citronnier", "Fait : Tailler (Citronnier)", "Fait : Poubelle jaune".
  def done_label
    return t(".done_watering", name: task.subject.name) if task.watering?
    return t(".done_with_subject", title: task.title, subject: task.subject.name) if task.subject

    t(".done", title: task.title)
  end

  def done_today_label
    task.watering? ? t(".watered_today") : t(".done_today")
  end
end
