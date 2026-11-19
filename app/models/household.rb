class Household < ApplicationRecord
  has_many :members, class_name: "HouseholdMember", dependent: :destroy
  has_many :users, through: :members
  has_many :locations, dependent: :destroy

  validates :name, presence: true
  validates :time_zone, inclusion: { in: TZInfo::Timezone.all_identifiers }
  validates :altitude_m, numericality: { only_integer: true, in: -500..9000 }, allow_nil: true

  def located?
    latitude.present? && longitude.present?
  end
end
