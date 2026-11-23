module Photos
  # Adds a photo to a subject (a plant…). The upload is normalized before being stored: rotated upright, at most
  # 2048 px, saved as JPEG without any metadata (EXIF GPS would reveal where the house is). The shooting date is read
  # from the EXIF data first; without a plausible one, the photo is dated now.
  class Add
    include Dry::Monads[:result, :do]

    MAX_DIMENSION = 2048
    EXIF_DATE = "exif-ifd2-DateTimeOriginal".freeze
    EXIF_OFFSET = "exif-ifd2-OffsetTimeOriginal".freeze
    OLDEST_PLAUSIBLE = Time.utc(2000)

    def call(subject:, file:)
      yield check_subject(subject)
      upload = yield validate_upload(file)
      normalized = yield normalize(upload)
      image = upload_image(subject, normalized)

      Success(subject.photos.create!(taken_at: shooting_time(file), image:))
    ensure
      normalized&.close!
    end

    private

    def check_subject(subject)
      archived = subject.respond_to?(:archived?) && subject.archived?
      archived ? Failure[:subject_archived, subject] : Success(subject)
    end

    def validate_upload(file)
      upload = PhotoUpload.new(file:)
      upload.valid? ? Success(upload) : Failure[:invalid, upload]
    end

    def normalize(upload)
      Success(
        ImageProcessing::Vips
          .source(upload.file.path)
          .loader(fail: true) # strict: corrupted or truncated pixel data is an error, not a half grey picture
          .autorot
          .resize_to_limit(MAX_DIMENSION, MAX_DIMENSION)
          .convert("jpg")
          .saver(strip: true, quality: 85)
          .call
      )
    rescue Vips::Error, ImageProcessing::Error
      upload.errors.add(:file, :not_a_picture)
      Failure[:invalid, upload]
    end

    # Uploaded right away: inside a caller's transaction, a deferred upload would run after the temp file is gone.
    def upload_image(subject, normalized)
      ActiveStorage::Blob.create_and_upload!(
        io: normalized,
        filename: "#{subject.model_name.element}-#{subject.id}.jpg",
        content_type: "image/jpeg"
      )
    end

    # EXIF dates look like "2026:11:10 08:15:00"; without an offset they are taken in the app time zone.
    def shooting_time(file)
      exif_time(file) || Time.current
    end

    def exif_time(file)
      image = Vips::Image.new_from_file(file.path)
      fields = image.get_fields
      return unless fields.include?(EXIF_DATE)

      date, time = image.get(EXIF_DATE).to_s[0, 19].split
      offset = image.get(EXIF_OFFSET).to_s[/[+-]\d{2}:\d{2}/] if fields.include?(EXIF_OFFSET)
      shot_at = Time.zone.parse("#{date.tr(":", "-")} #{time}#{offset}")
      shot_at if shot_at&.between?(OLDEST_PLAUSIBLE, Time.current)
    rescue Vips::Error, ArgumentError, NoMethodError
      nil
    end
  end
end
