class Household < ApplicationRecord
  has_many :members, class_name: "HouseholdMember", dependent: :destroy
  has_many :users, through: :members

  validates :name, presence: true
  validates :time_zone, inclusion: { in: TZInfo::Timezone.all_identifiers }
end
