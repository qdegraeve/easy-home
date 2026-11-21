# The open occurrences of a list (home page), one row per gesture rather than per object (UX review): all the
# waterings of the list on a single line, "Arroser · 4", done in one tap or detailed by location; the other tasks one
# row each. A single watering keeps its own row, with the plant's name.
class TaskListComponent < ViewComponent::Base
  def initialize(occurrences:, title:, id:, empty: nil)
    @title = title
    @id = id
    @empty = empty
    waterings, @others = occurrences.partition { |occurrence| occurrence.task.watering? }
    @waterings = waterings.size > 1 ? waterings : []
    @others = waterings + @others if waterings.size == 1
  end

  private

  attr_reader :waterings, :others, :title, :id, :empty

  # "Terrasse 3 · salon 1": where the plants to water are, by location (plants without location last).
  def watering_places
    counts = waterings.map { |occurrence| occurrence.task.subject.location&.name }.tally
    counts.sort_by { |name, _| [ name ? 0 : 1, name.to_s ] }.map do |name, count|
      "#{name || t('.no_location')} #{count}"
    end.join(" · ").upcase_first
  end
end
