# Input for a manual task of a subject (fertilizer, pruning…): once on a date, or every N days starting from a
# date. The repetition type is chosen on creation and never changes afterwards. "À ne pas rater" makes it critical
# (Task#importance): first in the list, in red, no tolerance.
class TaskForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  KINDS = %w[once sliding].freeze

  attribute :title, :string
  attribute :recurrence_type, :string, default: "once"
  attribute :due_on, :date
  attribute :interval_days, :integer
  attribute :critical, :boolean, default: false

  validates :title, presence: true, length: { maximum: 100 }
  validates :recurrence_type, inclusion: { in: KINDS }
  validates :due_on, presence: true
  validates :interval_days,
    numericality: { only_integer: true, in: Recurrence::Sliding::INTERVAL_DAYS },
    if: :sliding?

  def self.model_name
    ActiveModel::Name.new(self, nil, "Task")
  end

  def self.from(task)
    recurrence = task.recurrence
    new(
      title: task.title,
      recurrence_type: task.recurrence_type,
      due_on: task.once? ? recurrence.due_on : (task.pending_occurrence&.due_at&.to_date || recurrence.start_on),
      interval_days: (recurrence.interval_days if task.sliding?),
      critical: task.critical?
    )
  end

  def sliding?
    recurrence_type == "sliding"
  end

  def task_attributes
    { title: title.strip, recurrence_type:, recurrence_config:, importance: critical ? "critical" : "flexible" }
  end

  private

  def recurrence_config
    if sliding?
      { "interval_days" => interval_days, "start_on" => due_on.iso8601 }
    else
      { "due_on" => due_on.iso8601 }
    end
  end
end
