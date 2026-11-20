# An uploaded picture, checked on its content rather than on its file name: JPEG, PNG or WebP, 15 MB and 100
# megapixels at most. Dimensions are read from the header only, so a small file declaring huge dimensions (a
# decompression bomb) is refused before any processing.
class PhotoUpload
  include ActiveModel::Model

  CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_SIZE_MB = 15
  MAX_MEGAPIXELS = 100 # 50 MP phones and panoramas fit; normalization shrinks everything to 2048 px anyway

  attr_accessor :file

  validates :file, presence: true
  validate :file_must_be_a_picture

  def self.model_name
    ActiveModel::Name.new(self, nil, "Photo")
  end

  private

  def file_must_be_a_picture
    return if file.blank?
    return errors.add(:file, :not_a_picture) unless file.respond_to?(:path) && file.respond_to?(:size)
    return errors.add(:file, :too_large, count: MAX_SIZE_MB) if file.size > MAX_SIZE_MB.megabytes
    return errors.add(:file, :not_a_picture) unless CONTENT_TYPES.include?(content_type)

    pixels = header_pixels
    return errors.add(:file, :not_a_picture) if pixels.nil?

    errors.add(:file, :too_many_pixels, count: MAX_MEGAPIXELS) if pixels > MAX_MEGAPIXELS * 1_000_000
  end

  def content_type
    File.open(file.path, "rb") { |io| Marcel::MimeType.for(io) }
  end

  def header_pixels
    image = Vips::Image.new_from_file(file.path)
    image.width * image.height
  rescue Vips::Error
    nil
  end
end
