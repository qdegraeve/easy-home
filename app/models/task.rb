class Task < ApplicationRecord
  belongs_to :household
  belongs_to :subject, polymorphic: true, optional: true
  has_many :occurrences, class_name: "TaskOccurrence", dependent: :destroy
  has_one :pending_occurrence, -> { pending }, class_name: "TaskOccurrence"

  # Les droits passent par le foyer de la tâche : il ne doit jamais diverger de celui du sujet (voir ADR 0010).
  attr_readonly :household_id

  enum :recurrence_type, { sliding: "sliding" }, validate: true

  validates :title, presence: true
  validate :subject_must_belong_to_household
  validate :recurrence_must_be_valid

  def recurrence
    Recurrence.build(type: recurrence_type, config: recurrence_config)
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
