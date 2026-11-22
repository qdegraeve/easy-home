# The rain of a day at a household, fetched once in the evening (Plants::RecordRain, ADR 0015): one row per household
# and day, so that the weather service is called once and the rule is applied once.
class Rainfall < ApplicationRecord
  belongs_to :household

  validates :fell_on, presence: true, uniqueness: { scope: :household_id }
  validates :millimeters, numericality: { greater_than_or_equal_to: 0 }

  def effect
    Rain.effect(millimeters)
  end
end
