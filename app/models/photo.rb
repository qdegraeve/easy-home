class Photo < ApplicationRecord
  belongs_to :plant
  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_fill: [ 320, 320 ]
    attachable.variant :large, resize_to_limit: [ 1600, 1600 ]
  end

  validates :taken_at, presence: true, comparison: { less_than_or_equal_to: -> { Time.current }, message: :in_future }
  validates :image, presence: true
end
