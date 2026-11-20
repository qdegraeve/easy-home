module PlantAnalyzer
  # The copy of a photo sent to the AI: at most 1568 px, JPEG without any metadata (ADR 0008).
  module Image
    DIMENSION = 1568

    def self.from(photo)
      photo.image.blob.open do |file|
        Vips::Image.thumbnail(file.path, DIMENSION, height: DIMENSION, size: :down)
          .write_to_buffer(".jpg", Q: 85, strip: true)
      end
    end
  end
end
