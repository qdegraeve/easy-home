# A place in a household (ADR 0019): a person with a role, or, until an invitation is accepted, a place reserved for
# someone (no user yet). A reserved place gives no right and is counted nowhere. A guest sees the tasks of the subjects
# opened to them (GuestAccess), or all of them (guest_full_access), during their optional period.
class HouseholdMember < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :household
  has_one :invitation, dependent: :destroy
  has_many :guest_accesses, dependent: :delete_all

  enum :role, { manager: "manager", member: "member", guest: "guest" }, validate: true

  normalizes :invitee_name, with: ->(name) { name.squish.presence }

  validates :user_id, uniqueness: { scope: :household_id }, allow_nil: true
  validates :user, presence: true, unless: :invitation
  validates :invitee_name, length: { maximum: 50 }
  validates :access_ends_on, comparison: { greater_than_or_equal_to: :access_starts_on },
                             allow_nil: true, if: :access_starts_on

  scope :joined, -> { where.not(user_id: nil) }
  # Reserved places whose link can still be used.
  scope :invited, -> { where(user_id: nil).joins(:invitation).merge(Invitation.usable) }
  # Guests whose period includes this day (no period: always).
  scope :guests_on, lambda { |date|
    guest.where(access_starts_on: [ nil, ..date ]).where(access_ends_on: [ nil, date.. ])
  }

  def pending?
    user_id.nil?
  end

  # The period of a guest: "upcoming", "over", or nil while it lasts (or without one).
  def access_period_state(date = Time.zone.today)
    return :upcoming if access_starts_on && date < access_starts_on
    :over if access_ends_on && date > access_ends_on
  end
end
