class Location < ApplicationRecord
  belongs_to :household
  has_many :plants, dependent: :nullify

  enum :exposure, { full_sun: "full_sun", partial_shade: "partial_shade", shade: "shade" }, validate: true

  validates :name, presence: true, uniqueness: { scope: :household_id, case_sensitive: false }
end
