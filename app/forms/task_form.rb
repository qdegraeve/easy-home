# Saisie d'une tâche manuelle d'un sujet (engrais, taille…) : une seule fois à une date, ou tous les N jours à
# partir d'une date. Le type de répétition se choisit à la création et ne change plus ensuite.
class TaskForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  KINDS = %w[once sliding].freeze

  attribute :title, :string
  attribute :recurrence_type, :string, default: "once"
  attribute :due_on, :date
  attribute :interval_days, :integer

  validates :title, presence: true, length: { maximum: 100 }
  validates :recurrence_type, inclusion: { in: KINDS }
  validates :due_on, presence: true
  validates :interval_days,
    numericality: { only_integer: true, in: Recurrence::Sliding::INTERVAL_DAYS },
    if: :sliding?

  def self.model_name = ActiveModel::Name.new(self, nil, "Task")

  def self.from(task)
    recurrence = task.recurrence
    new(
      title: task.title,
      recurrence_type: task.recurrence_type,
      due_on: task.once? ? recurrence.due_on : (task.pending_occurrence&.due_at&.to_date || recurrence.start_on),
      interval_days: (recurrence.interval_days if task.sliding?)
    )
  end

  def sliding? = recurrence_type == "sliding"

  def task_attributes
    { title: title.strip, recurrence_type:, recurrence_config: }
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
