module Plants
  # Runs a pending AI analysis: prepares the photos (1568 px, no metadata), describes the context (never the
  # address, see ADR 0008), asks the analyzer, checks its answer strictly, then stores the result or the failure and
  # refreshes the open plant pages.
  class Analyze
    include Dry::Monads[:result, :do]

    PHOTO_DIMENSION = 1568

    def call(analysis:)
      yield check_pending(analysis)
      result = answer_for(analysis)
      result.success? ? record_answer(analysis, result.value!) : record_failure(analysis, result.failure)
      analysis.plant.broadcast_refresh

      result.fmap { analysis }
    end

    private

    def check_pending(analysis)
      analysis.pending? ? Success(analysis) : Failure[:not_pending, analysis]
    end

    def answer_for(analysis)
      images = analysis.photos_oldest_first.map { |photo| prepared_image(photo) }
      raw = yield ask(images, PlantAnalyzer::Context.new(analysis).to_text)
      check_answer(raw)
    end

    def ask(images, text)
      Success(PlantAnalyzer.adapter.analyze(images:, text:))
    rescue PlantAnalyzer::Error => error
      Failure[:external_error, error.message]
    end

    def check_answer(raw)
      answer = PlantAnalysisAnswer.new(raw)
      answer.valid? ? Success(answer) : Failure[:invalid_answer, answer.errors.attribute_names.join(", ")]
    end

    def prepared_image(photo)
      photo.image.blob.open do |file|
        Vips::Image.thumbnail(file.path, PHOTO_DIMENSION, height: PHOTO_DIMENSION, size: :down)
          .write_to_buffer(".jpg", Q: 85, strip: true)
      end
    end

    def record_answer(analysis, answer)
      analysis.update!(
        **answer.attributes,
        status: :done,
        model: PlantAnalyzer.adapter.try(:model),
        finished_at: Time.current
      )
    end

    def record_failure(analysis, (code, message))
      analysis.update!(status: :failed, error: "#{code}: #{message}".truncate(250), finished_at: Time.current)
    end
  end
end
