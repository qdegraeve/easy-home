# What the household maintains and the app reminds of (ADR 0016): generic, a kind of the catalogue (its icon, its
# suggestions; "other" for one of its own), a name, and what is good to know ("À savoir"). Its tasks and photos hang on
# it; deleting it deletes them, with their history. Never archived (contract of a subject: archived? is false).
class Equipment < ApplicationRecord
  NOTES_MAX = 10_000

  belongs_to :household
  has_many :tasks, as: :subject, dependent: :destroy, inverse_of: :subject
  has_many :guest_accesses, as: :subject, dependent: :delete_all
  has_many :photos, -> { order(taken_at: :desc, id: :desc) }, as: :subject, dependent: :destroy, inverse_of: :subject

  # Authorization goes through the household: it never changes (ADR 0010).
  attr_readonly :household_id

  normalizes :name, :notes, with: ->(value) { value.strip.presence }
  # Named after its kind when no name is typed ("Lave-vaisselle"): an attribute default, nothing else.
  before_validation { self.name ||= kind_info&.name }

  validates :kind, inclusion: { in: ->(_) { Catalogue.equipment_kind_keys } }, if: :kind_changed?
  validates :name, presence: true, length: { maximum: 100 }
  validates :notes, length: { maximum: NOTES_MAX }

  # Its kind in the catalogue; a kind the catalogue no longer has reads as "Autre" (a catalogue change never breaks
  # what exists, ADR 0016).
  def kind_info
    Catalogue.equipment_kind(kind) || Catalogue.equipment_kind("other")
  end

  # Its face: the latest photo, if any.
  def face
    photos.first
  end

  # The mark of its tasks in the lists (contract of a subject: a subject may give its own).
  def icon
    kind_info.icon
  end

  def archived?
    false
  end
end
