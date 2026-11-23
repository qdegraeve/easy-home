# Input for a manual task, of a plant (fertilizer, pruning…) or of the house itself (no subject): once on a date,
# every N days, weeks, months or years after the last time, or on fixed dates (every N weeks on the weekday of
# "Prochaine fois le", or every N years on that day). The rhythm can be changed when editing. "À ne pas rater" makes it
# critical (Task#importance): first in the list, in red, no tolerance. "Comment faire" (instructions) is optional, read
# when doing the task. A suggestion of the catalogue (suggestion_key) prefills the form and is kept as the origin of
# the task.
class TaskForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  KINDS = %w[once sliding fixed].freeze
  UNITS = { "sliding" => Recurrence::Sliding::UNITS, "fixed" => Recurrence::Fixed::UNITS }.freeze
  ALL_UNITS = Recurrence::Sliding::UNITS.keys.freeze

  attribute :title, :string
  attribute :recurrence_type, :string, default: "once"
  attribute :due_on, :date
  attribute :interval, :integer, default: 1
  attribute :unit, :string, default: "weeks"
  attribute :critical, :boolean, default: false
  attribute :instructions, :string
  attribute :suggestion_key, :string
  # "19:00", or blank for no reminder (the morning digest only); a reminder on the due day (ADR 0017).
  attribute :reminder_time, :string

  validates :title, presence: true, length: { maximum: 100 }
  validates :recurrence_type, inclusion: { in: KINDS }
  validates :due_on, presence: true
  validates :instructions, length: { maximum: Task::INSTRUCTIONS_MAX }
  validate :interval_must_fit_unit, if: :repeating?
  validates :reminder_time, inclusion: { in: ->(_form) { reminder_times } }, allow_blank: true

  def self.reminder_times
    User::DIGEST_MINUTES.map { |minute| ReminderTime.to_field(minute) }
  end

  def self.model_name
    ActiveModel::Name.new(self, nil, "Task")
  end

  def self.from(task)
    recurrence = task.recurrence
    new(
      title: task.title,
      recurrence_type: task.recurrence_type,
      due_on: task.pending_occurrence&.due_at&.to_date || first_day(recurrence),
      interval: (task.once? ? 1 : recurrence.interval),
      unit: (task.once? ? "weeks" : recurrence.unit),
      critical: task.critical?,
      instructions: task.instructions,
      reminder_time: ReminderTime.to_field(task.reminder_minute)
    )
  end

  # A suggestion of the catalogue, copied into the form (everything stays editable); its first date when it has one.
  def self.from_suggestion(suggestion, today: Time.zone.today)
    rule = suggestion.recurrence
    new(
      title: suggestion.title,
      recurrence_type: rule.fetch("type"),
      due_on: suggestion.first_due_on(today:),
      interval: rule.fetch("interval", 1),
      unit: rule.fetch("unit", "weeks"),
      critical: suggestion.critical?,
      instructions: suggestion.instructions,
      reminder_time: ReminderTime.to_field(suggestion.reminder_minute),
      suggestion_key: suggestion.key
    )
  end

  def self.first_day(recurrence)
    case recurrence
    when Recurrence::Once then recurrence.due_on
    when Recurrence::Fixed then recurrence.anchor_on
    else recurrence.start_on
    end
  end

  def sliding?
    recurrence_type == "sliding"
  end

  def fixed?
    recurrence_type == "fixed"
  end

  def repeating?
    sliding? || fixed?
  end

  def task_attributes
    {
      title: title.strip,
      recurrence_type:,
      recurrence_config:,
      importance: critical ? "critical" : "flexible",
      instructions: instructions.to_s.strip.presence,
      reminder_minute: ReminderTime.from_field(reminder_time),
      suggestion_key: (suggestion_key if Catalogue.suggestion(suggestion_key))
    }
  end

  private

  def recurrence_config
    if sliding?
      { "interval" => interval, "unit" => unit, "start_on" => due_on.iso8601 }
    elsif fixed?
      { "anchor_on" => due_on.iso8601, "interval" => interval, "unit" => unit }
    else
      { "due_on" => due_on.iso8601 }
    end
  end

  # Every N days (1 to 60), weeks (1 to 52), months (1 to 24) or years (1 to 10) after the last time; fixed dates in
  # weeks or years only.
  def interval_must_fit_unit
    range = UNITS.fetch(recurrence_type)[unit]
    return if range && interval.is_a?(Integer) && range.cover?(interval)

    errors.add(:interval, fixed? ? :fixed_range : :sliding_range)
  end
end
