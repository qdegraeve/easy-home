class Task < ApplicationRecord
  belongs_to :household
  belongs_to :subject, polymorphic: true, optional: true
  has_many :occurrences, class_name: "TaskOccurrence", dependent: :destroy
  has_one :pending_occurrence, -> { pending }, class_name: "TaskOccurrence"
  # Photos of the task, shown in its sheet with how to do it ("the filter to unscrew").
  has_many :photos, -> { order(taken_at: :desc, id: :desc) }, as: :subject, dependent: :destroy, inverse_of: :subject

  # Authorization goes through the task's household: it must never diverge from the subject's (see ADR 0010).
  attr_readonly :household_id

  enum :recurrence_type, { sliding: "sliding", once: "once", fixed: "fixed" }, validate: true
  # Flexible (watering, upkeep: a tolerance before missed) or critical ("à ne pas rater": first, in red, no tolerance).
  enum :importance, { flexible: "flexible", critical: "critical" }, validate: true

  scope :active, -> { where(active: true) }
  # Tasks of the house itself (bins…), attached to neither a plant nor an equipment.
  scope :without_subject, -> { where(subject_type: nil) }
  # Still to do: active with an open occurrence (a one-off task once done has none, it stays in the journal).
  scope :to_do, -> { active.joins(:pending_occurrence) }

  INSTRUCTIONS_MAX = 5_000

  validates :title, presence: true, length: { maximum: 100 }
  validates :instructions, length: { maximum: INSTRUCTIONS_MAX }
  # Reminder on the due day, at this minute of the day (ADR 0017); nil: the morning digest only.
  validates :reminder_minute, inclusion: { in: User::DIGEST_MINUTES }, allow_nil: true
  validate :subject_must_belong_to_household
  validate :recurrence_must_be_valid

  def recurrence
    Recurrence.build(type: recurrence_type, config: recurrence_config)
  end

  # The open occurrence is where the rain put it (Plants::RecordRain postponing it): the last closed occurrence is a
  # rain postponement and the open one still has the date Tasks::Postpone gave it, not one a missed watering or an edit
  # of the task set since.
  def moved_by_rain?
    last_closed = occurrences.where(status: %i[done missed postponed]).order(completed_at: :desc, id: :desc).first
    return false unless last_closed&.postponed? && last_closed.by_rain? && pending_occurrence

    pending_occurrence.due_at.to_date == [ last_closed.due_at.to_date, last_closed.completed_at.to_date ].max + 1
  end

  # A stopped task (its plant archived) takes no new photo (contract of a photo subject).
  def archived?
    !active?
  end

  # Task added by hand (fertilizer, pruning, bins…), as opposed to a task created with its subject (watering).
  def manual?
    template_key.nil?
  end

  def watering?
    template_key == Plant::WATERING_TEMPLATE_KEY
  end

  # Days a late occurrence stays to do before it is missed, or nil when never missed (see Tolerance).
  def grace_days
    Tolerance.grace_days(importance:, recurrence:)
  end

  # The occurrence to act on when a page showed one closed since: the one still open of the task, if any, after a
  # postponement (the same task, moved) or a miss that reopened it on the same date. A miss that moved the task to
  # the next date of its rule (fixed dates, Tolerance.after_miss) is not caught up: the occurrence stays missed and
  # the stale tap fails, rather than doing the next collection. A pending or done occurrence stays itself.
  def still_open(occurrence)
    return occurrence unless occurrence.missed? || occurrence.postponed?

    pending = occurrences.pending.first
    return occurrence unless pending
    return pending if occurrence.postponed? || pending.due_at == occurrence.due_at

    occurrence
  end

  # due_at moved forward when it would start past the tolerance (see Tolerance.earliest).
  def due_within_tolerance(due_at)
    Tolerance.earliest(due_at, grace_days:, today: Time.zone.today)
  end

  # The first due date of a task added or edited with "Prochaine fois le" (on): that day, never past the tolerance; for
  # fixed dates, the first date of the rule from there (a past anchor jumps to its next date, like a collection), which
  # then becomes the anchor, so that the series never starts before it (Tasks::Reschedule replays from the anchor).
  def first_due_at!(on)
    return due_within_tolerance(on.in_time_zone) unless fixed?

    due_at = recurrence.next_due_at(last_completed_at: nil, not_before: Time.zone.today - grace_days.to_i)
    self.recurrence_config = recurrence_config.merge("anchor_on" => due_at.to_date.iso8601)
    save! if persisted? && changed?
    due_at
  end

  def after_miss
    Tolerance.after_miss(importance:, recurrence:)
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
