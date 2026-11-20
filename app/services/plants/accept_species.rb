module Plants
  # Sets the species proposed by an AI analysis on its plant, marked as coming from the AI (ADR 0008).
  class AcceptSpecies
    include Dry::Monads[:result, :do]

    def call(analysis:)
      yield check_proposal(analysis)
      update_plant(analysis)
    end

    private

    def check_proposal(analysis)
      return Failure[:not_acceptable, analysis] unless analysis.done? && analysis.species_name
      return Failure[:subject_archived, analysis] if analysis.plant.archived?

      Success(analysis)
    end

    def update_plant(analysis)
      plant = analysis.plant
      plant.update(species: analysis.species_name, species_source: :ai) ? Success(plant) : Failure[:invalid, plant]
    end
  end
end
