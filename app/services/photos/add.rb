module Photos
  # Adds a photo to a plant. The upload is normalized before being stored: rotated upright, at most 2048 px, saved
  # as JPEG without any metadata (EXIF GPS would reveal where the house is).
  class Add
    include Dry::Monads[:result]

    MAX_DIMENSION = 2048

    def call(plant:, file:)
      return Failure[:subject_archived, plant] if plant.archived?

      upload = PhotoUpload.new(file:)
      return Failure[:invalid, upload] unless upload.valid?

      normalized = normalize(file)
      unless normalized
        upload.errors.add(:file, :not_a_picture)
        return Failure[:invalid, upload]
      end

      photo = plant.photos.create!(
        taken_at: Time.current,
        image: { io: normalized, filename: "plant-#{plant.id}.jpg", content_type: "image/jpeg" }
      )
      Success(photo)
    ensure
      normalized&.close!
    end

    private

    def normalize(file)
      ImageProcessing::Vips
        .source(file.path)
        .autorot
        .resize_to_limit(MAX_DIMENSION, MAX_DIMENSION)
        .convert("jpg")
        .saver(strip: true, quality: 85)
        .call
    rescue Vips::Error, ImageProcessing::Error
      nil
    end
  end
end
