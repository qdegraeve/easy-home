# The photos of a subject (a plant, an equipment, a task) as a gallery (UX review, plant photo gallery): grouped by
# month, newest first, square tiles from edge to edge on a phone; the cover photo of a plant is marked. Each tile
# opens its photo.
#
#   render PhotoGridComponent.new(subject: @plant, photos: @photos)
class PhotoGridComponent < ViewComponent::Base
  def initialize(subject:, photos:)
    @subject = subject
    @photos = photos
  end

  private

  attr_reader :subject, :photos

  # [[first day of the month, photos of that month]], in the order of the photos (newest first).
  def months
    photos.group_by { |photo| photo.taken_at.to_date.beginning_of_month }
  end

  def cover?(photo)
    photo.id == subject.try(:cover_photo_id)
  end

  def alt(photo)
    t("plants.show.photo_alt", date: l(photo.taken_at.to_date, format: :day))
  end
end
