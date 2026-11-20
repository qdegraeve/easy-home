module Plants
  # Answers a pending follow-up question: sends the photos (analysis photos, then the ones attached to the
  # questions, prepared like for an analysis) and the whole conversation, then stores the answer or the failure and
  # refreshes the open plant pages (ADR 0008).
  class AnswerQuestion
    include Dry::Monads[:result, :do]

    def call(question:)
      yield check_pending(question)
      result = answer_for(question)
      result.success? ? record_answer(question, result.value!) : record_failure(question, result.failure)
      question.analysis.plant.broadcast_refresh

      result.fmap { question }
    end

    private

    def check_pending(question)
      question.pending? ? Success(question) : Failure[:not_pending, question]
    end

    def answer_for(question)
      context = PlantAnalyzer::FollowUpContext.new(question)
      images = context.photos.map { |photo| PlantAnalyzer::Image.from(photo) }
      answer = yield ask(images, context.to_text)
      check_answer(answer)
    end

    def ask(images, text)
      Success(PlantAnalyzer.adapter.answer(images:, text:))
    rescue PlantAnalyzer::Error => error
      Failure[:external_error, error.message]
    end

    def check_answer(answer)
      text = answer.to_s.strip if answer.is_a?(String)
      return Failure[:invalid_answer, "empty"] if text.blank?
      return Failure[:invalid_answer, "too long"] if text.length > PlantAnalyzer::MAX_ANSWER_LENGTH

      Success(text)
    end

    def record_answer(question, answer)
      question.update!(
        answer:,
        status: :done,
        model: PlantAnalyzer.adapter.try(:model),
        finished_at: Time.current
      )
    end

    def record_failure(question, (code, message))
      question.update!(status: :failed, error: "#{code}: #{message}".truncate(250), finished_at: Time.current)
    end
  end
end
