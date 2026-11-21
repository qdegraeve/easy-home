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

  def done_label
    if task.watering?
      t("plants.water_label", name: task.subject.name)
    else
      t("tasks.done_label", title: task.title, subject: task.subject.name)
    end
  end

  def done_today_label
    task.watering? ? t("plants.show.watered_today") : t("plants.show.done_today")
  end
end
