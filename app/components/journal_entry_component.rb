# One line of the journal (UX review, "qui a fait quoi"): what changes from a line to the next first (the plant
# watered, the task done), then what happened, who did it and when. A completion can be undone from here; a postponed
# or missed occurrence is a discreet line, nothing to undo. Used by the journal and by "Fait aujourd'hui".
#
#   render JournalEntryComponent.new(entry: occurrence, user: Current.user)
#   => Basilic / Arrosé · par Sam · 18 h 00   [Annuler]
class JournalEntryComponent < ViewComponent::Base
  def initialize(entry:, user:)
    @entry = entry
    @task = entry.task
    @user = user
  end

  private

  attr_reader :entry, :task, :user

  def title
    task.watering? ? task.subject&.name || task.title : task.title
  end

  # "Arrosé · par Sam · 18 h 00", "Citronnier · Échéance reportée · par vous", "Non fait, prévu le lun 16 nov.".
  def meta
    parts = [ (task.subject.name if task.subject && !task.watering?) ]
    if entry.missed?
      parts << t(task.watering? ? ".watering_missed" : ".missed", date: l(entry.due_at.to_date, format: :day))
    elsif entry.postponed?
      parts += [ t(task.watering? ? ".watering_postponed" : ".postponed"), author ]
    else
      parts += [ (t(".watered") if task.watering? && !entry.by_rain?), author, l(entry.completed_at, format: :hour) ]
    end
    parts.compact.join(" · ")
  end

  # "par vous", "par Sam", "par la pluie", or nothing. Until people have a name, the start of the e-mail, up to the
  # first dot or underscore ("sam.dupont@…" gives "Sam").
  def author
    return t(entry.done? && task.watering? ? ".watered_by_rain" : ".by_rain") if entry.by_rain?
    return unless entry.completed_by
    return t(".by_you") if entry.completed_by == user

    t(".by", name: entry.completed_by.email.split(/[@._]/).first.upcase_first)
  end

  def icon_name
    return :x if entry.missed?
    return :redo_2 if entry.postponed?
    return :cloud_rain if entry.by_rain?

    task.watering? ? :droplet : :check
  end

  # "Arrosage · Basilic", "Tailler · Citronnier": names the line in the cancel button and its confirmation.
  def what
    return t(".what_watering", name: task.subject.name) if task.watering? && task.subject

    task.subject ? t(".what_task", title: task.title, name: task.subject.name) : task.title
  end

  # Nothing is rescheduled for a stopped task (an archived plant): the confirmation does not promise it.
  def confirm_message
    t(task.active? ? ".cancel_confirm" : ".cancel_confirm_stopped", what:, date: date_label)
  end

  def date_label
    l(entry.completed_at.to_date, format: :day)
  end
end
