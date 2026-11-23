# The open occurrences of a list (home page), one row per gesture rather than per object (UX review): all the
# waterings of the list on a single line, "Arroser · 4", done in one tap or detailed by location; the other tasks one
# row each. A single watering keeps its own row, with the plant's name. The tasks that must not be missed come first.
class TaskListComponent < ViewComponent::Base
  def initialize(occurrences:, title:, id:, empty: nil)
    @title = title
    @id = id
    @empty = empty
    waterings, @others = occurrences.partition { |occurrence| occurrence.task.watering? }
    @waterings = waterings.size > 1 ? waterings : []
    @others = waterings + @others if waterings.size == 1
    @critical, @others = @others.partition { |occurrence| occurrence.task.critical? }
  end

  private

  attr_reader :critical, :waterings, :others, :title, :id, :empty

  # The gesture first (UX review, "une ligne par geste"): "Traiter au savon noir" over "Citronnier". A watering keeps
  # the plant as its title, the drop says the gesture, and leads to the plant; any other task opens its sheet (what
  # to do and how). A task of the house has no detail.
  def row(occurrence)
    task = occurrence.task
    TaskRowComponent.new(
      occurrence:,
      title: task.watering? ? task.subject.name : task.title,
      href: task.watering? ? helpers.polymorphic_path(task.subject) : helpers.task_path(task),
      detail: row_detail(task),
      postpone: true
    )
  end

  def row_detail(task)
    return t(".watering") if task.watering?

    task.subject&.name
  end

  # "Terrasse 3 · salon 1": where the plants to water are, by location (plants without location last).
  def watering_places
    counts = waterings.map { |occurrence| occurrence.task.subject.location&.name }.tally
    counts.sort_by { |name, _| [ name ? 0 : 1, name.to_s ] }.map do |name, count|
      "#{name || t('.no_location')} #{count}"
    end.join(" · ").upcase_first
  end
end
