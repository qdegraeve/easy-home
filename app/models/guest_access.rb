# A subject opened to a guest (ADR 0019): a plant, an equipment, or the household itself for the tasks of the house.
# All its tasks, present and future, become visible to the guest during their period.
class GuestAccess < ApplicationRecord
  SUBJECT_TYPES = %w[Plant Equipment Household].freeze

  belongs_to :household_member
  belongs_to :subject, polymorphic: true

  validates :subject_type, inclusion: { in: SUBJECT_TYPES }
  validates :subject_id, uniqueness: { scope: %i[household_member_id subject_type] }
  validate :subject_of_the_household

  private

  def subject_of_the_household
    household_id = subject.is_a?(Household) ? subject.id : subject&.household_id
    errors.add(:subject, :invalid) unless household_id && household_id == household_member&.household_id
  end
end
