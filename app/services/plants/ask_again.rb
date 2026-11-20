module Plants
  # Asks a failed follow-up question again, with the same text and photo.
  class AskAgain
    include Dry::Monads[:result, :do]

    def call(question:)
      yield check_question(question)
      yield reset(question)
      AnswerQuestionJob.perform_later(question)

      Success(question)
    end

    private

    def check_question(question)
      return Failure[:subject_archived, question] if question.analysis.plant.archived?
      return Failure[:not_failed, question] unless question.failed?

      Success(question)
    end

    def reset(question)
      question.update!(status: :pending, answer: nil, error: nil, finished_at: nil)
      Success(question)
    rescue ActiveRecord::RecordNotUnique # another question of the analysis is waiting for its answer
      Failure[:already_pending, question]
    end
  end
end
