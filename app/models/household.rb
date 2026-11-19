class Household < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  validates :name, presence: true
  validates :time_zone, inclusion: { in: TZInfo::Timezone.all_identifiers }
end
