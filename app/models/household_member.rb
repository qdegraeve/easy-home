# A place in a household (ADR 0019): a person with a role, or, until an invitation is accepted, a place reserved for
# someone (no user yet). A reserved place gives no right and is counted nowhere.
class HouseholdMember < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :household
  has_one :invitation, dependent: :destroy

  enum :role, { manager: "manager", member: "member", guest: "guest" }, validate: true

  normalizes :invitee_name, with: ->(name) { name.squish.presence }

  validates :user_id, uniqueness: { scope: :household_id }, allow_nil: true
  validates :user, presence: true, unless: :invitation
  validates :invitee_name, length: { maximum: 50 }

  scope :joined, -> { where.not(user_id: nil) }
  # Reserved places whose link can still be used.
  scope :invited, -> { where(user_id: nil).joins(:invitation).merge(Invitation.usable) }

  def pending?
    user_id.nil?
  end
end
