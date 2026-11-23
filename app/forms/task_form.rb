# Input for a manual task, of a plant (fertilizer, pruning…) or of the house itself (no subject): once on a date,
# every N days after the last time, or on fixed dates (every N weeks on the weekday of "Prochaine fois le", or every N
# years on that day). The rhythm can be changed when editing. "À ne pas rater" makes it critical (Task#importance):
# first in the list, in red, no tolerance. "Comment faire" (instructions) is optional, read when doing the task. A
# suggestion of the catalogue (suggestion_key) prefills the form and is kept as the origin of the task.
class TaskForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  KINDS = %w[once sliding fixed].freeze
  FIXED_UNITS = Recurrence::Fixed::UNITS.keys.freeze

  attribute :title, :string
  attribute :recurrence_type, :string, default: "once"
  attribute :due_on, :date
  attribute :interval_days, :integer
  attribute :interval, :integer, default: 1
  attribute :unit, :string, default: "weeks"
  attribute :critical, :boolean, default: false
  attribute :instructions, :string
  attribute :suggestion_key, :string

  validates :title, presence: true, length: { maximum: 100 }
  validates :recurrence_type, inclusion: { in: KINDS }
  validates :due_on, presence: true
  validates :instructions, length: { maximum: Task::INSTRUCTIONS_MAX }
  validates :interval_days,
    numericality: { only_integer: true, in: Recurrence::Sliding::INTERVAL_DAYS },
    if: :sliding?
  validates :unit, inclusion: { in: FIXED_UNITS }, if: :fixed?
  validate :interval_must_fit_unit, if: :fixed?

  def self.model_name
    ActiveModel::Name.new(self, nil, "Task")
  end

  def self.from(task)
    recurrence = task.recurrence
    new(
      title: task.title,
      recurrence_type: task.recurrence_type,
      due_on: task.pending_occurrence&.due_at&.to_date || first_day(recurrence),
      interval_days: (recurrence.interval_days if task.sliding?),
      interval: (task.fixed? ? recurrence.interval : 1),
      unit: (task.fixed? ? recurrence.unit : "weeks"),
      critical: task.critical?,
      instructions: task.instructions
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

  def task_attributes
    {
      title: title.strip,
      recurrence_type:,
      recurrence_config:,
      importance: critical ? "critical" : "flexible",
      instructions: instructions.to_s.strip.presence,
      suggestion_key: (suggestion_key if Catalogue.suggestion(suggestion_key))
    }
  end

  private

  def recurrence_config
    if sliding?
      { "interval_days" => interval_days, "start_on" => due_on.iso8601 }
    elsif fixed?
      { "anchor_on" => due_on.iso8601, "interval" => interval, "unit" => unit }
    else
      { "due_on" => due_on.iso8601 }
    end
  end

  def interval_must_fit_unit
    range = Recurrence::Fixed::UNITS[unit]
    errors.add(:interval, :inclusion) unless range && interval.is_a?(Integer) && range.cover?(interval)
  end
end
