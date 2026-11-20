class Photo < ApplicationRecord
  belongs_to :plant
  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 320, 320 ]
    attachable.variant :large, resize_to_limit: [ 1600, 1600 ]
  end

  validates :taken_at, presence: true
  validates :image, presence: true
  validate :taken_on_must_be_a_past_date

  def taken_on = taken_at&.to_date

  # Changes the shooting day and keeps the time of day, so photos of the same day stay in their order.
  def taken_on=(value)
    date = value.is_a?(Date) ? value : Date.iso8601(value.to_s)
    @invalid_taken_on = false
    self.taken_at = (taken_at || Time.current).in_time_zone.change(year: date.year, month: date.month, day: date.day)
  rescue Date::Error
    @invalid_taken_on = true
  end

  private

  def taken_on_must_be_a_past_date
    if @invalid_taken_on
      errors.add(:taken_on, :invalid)
    elsif taken_at && taken_on > Time.zone.today
      errors.add(:taken_on, :in_future)
    end
  end
end
