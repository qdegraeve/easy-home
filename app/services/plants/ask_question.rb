module Plants
  # Asks a follow-up question on a finished analysis, with an optional new photo added to the plant's photos, then
  # queues the answer. One question at a time per analysis, and a bounded number of them (each one resends the
  # photos and the whole conversation).
  class AskQuestion
    include Dry::Monads[:result, :do]

    def call(analysis:, user:, params:)
      yield check_analysis(analysis)
      form = yield validate(params)
      question = yield create_question(analysis, user, form)
      AnswerQuestionJob.perform_later(question)

      Success(question)
    end

    private

    def check_analysis(analysis)
      return Failure[:subject_archived, analysis] if analysis.plant.archived?
      return Failure[:not_done, analysis] unless analysis.done?
      return Failure[:already_pending, analysis] if analysis.questions.pending.exists?
      return Failure[:too_many, analysis] if analysis.questions.count >= PlantAnalysisQuestion::MAX_PER_ANALYSIS

      Success(analysis)
    end

    def validate(params)
      form = QuestionForm.new(params.to_h)
      form.valid? ? Success(form) : Failure[:invalid, form]
    end

    def create_question(analysis, user, form)
      ActiveRecord::Base.transaction do
        photo = yield add_photo(analysis.plant, form) if form.photo.present?
        Success(analysis.questions.create!(asked_by: user, body: form.body.strip, photo:))
      end
    rescue ActiveRecord::RecordNotUnique # two questions at the same time: the unique index lets only one through
      Failure[:already_pending, analysis]
    end

    def add_photo(plant, form)
      Photos::Add.new.call(plant:, file: form.photo).or do |(_code, upload)|
        upload.errors.messages_for(:file).each { |message| form.errors.add(:photo, message) }
        Failure[:invalid, form]
      end
    end
  end
end
