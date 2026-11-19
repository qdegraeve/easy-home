# An uploaded picture, checked on its content rather than on its file name: JPEG, PNG or WebP, 15 MB at most.
class PhotoUpload
  include ActiveModel::Model

  CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_SIZE_MB = 15

  attr_accessor :file

  validates :file, presence: true
  validate :file_must_be_a_picture

  def self.model_name = ActiveModel::Name.new(self, nil, "Photo")

  private

  def file_must_be_a_picture
    return if file.blank?
    return errors.add(:file, :too_large, count: MAX_SIZE_MB) if file.size > MAX_SIZE_MB.megabytes

    content_type = File.open(file.path, "rb") { |io| Marcel::MimeType.for(io) }
    errors.add(:file, :not_a_picture) unless CONTENT_TYPES.include?(content_type)
  end
end
