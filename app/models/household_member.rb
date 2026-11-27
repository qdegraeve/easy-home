class HouseholdMember < ApplicationRecord
  belongs_to :user
  belongs_to :household

  enum :role, { manager: "manager", member: "member", guest: "guest" }, validate: true

  validates :user_id, uniqueness: { scope: :household_id }
end
