module Plants
  # Queues an AI analysis of a plant from the chosen photos (the latest one by default) and the user's note.
  class RequestAnalysis
    include Dry::Monads[:result, :do]

    def call(plant:, user:, params: {})
      yield check_plant(plant)
      request = yield validate_request(plant, params)
      analysis = create_analysis(plant, user, request)
      AnalyzePlantJob.perform_later(analysis)

      Success(analysis)
    end

    private

    def check_plant(plant)
      return Failure[:subject_archived, plant] if plant.archived?
      return Failure[:already_pending, plant] if plant.analyses.pending.exists?

      Success(plant)
    end

    def validate_request(plant, params)
      request = AnalysisRequest.new(params.to_h.merge(plant:))
      request.valid? ? Success(request) : Failure[:invalid, request]
    end

    def create_analysis(plant, user, request)
      plant.analyses.create!(requested_by: user, user_note: request.note.to_s.strip.presence, photos: request.photos)
    end
  end
end
