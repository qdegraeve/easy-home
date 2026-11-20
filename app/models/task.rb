class Task < ApplicationRecord
  belongs_to :household
  belongs_to :subject, polymorphic: true, optional: true
  has_many :occurrences, class_name: "TaskOccurrence", dependent: :destroy
  has_one :pending_occurrence, -> { pending }, class_name: "TaskOccurrence"

  # Authorization goes through the task's household: it must never diverge from the subject's (see ADR 0010).
  attr_readonly :household_id

  enum :recurrence_type, { sliding: "sliding", once: "once" }, validate: true

  scope :active, -> { where(active: true) }

  validates :title, presence: true, length: { maximum: 100 }
  validate :subject_must_belong_to_household
  validate :recurrence_must_be_valid

  def recurrence
    Recurrence.build(type: recurrence_type, config: recurrence_config)
  end

  # Task added by hand (fertilizer, pruning…), as opposed to a task created with its subject (watering).
  def manual?
    template_key.nil?
  end

  def watering?
    template_key == Plant::WATERING_TEMPLATE_KEY
  end

  private

  def subject_must_belong_to_household
    return if subject.nil? || subject.household_id == household_id

    errors.add(:subject, :invalid)
  end

  def recurrence_must_be_valid
    return if recurrence_type.blank?

    recurrence
  rescue Recurrence::InvalidConfig
    errors.add(:recurrence_config, :invalid)
  end
end
