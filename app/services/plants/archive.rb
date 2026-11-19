module Plants
  # Archive une plante (morte, donnée…) : plus d'échéance ni de rappel, mais la fiche et le journal restent.
  class Archive
    include Dry::Monads[:result]

    def call(plant:)
      return Failure[:already_archived, plant] if plant.archived?

      ActiveRecord::Base.transaction do
        plant.update!(archived_at: Time.current)
        plant.tasks.each do |task|
          task.update!(active: false)
          task.occurrences.pending.delete_all
        end
      end

      Success(plant)
    end
  end
end
