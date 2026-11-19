module Plants
  # Restaure une plante archivée : ses tâches reprennent, échéance recalculée depuis la dernière réalisation.
  class Restore
    include Dry::Monads[:result]

    def call(plant:)
      return Failure[:not_archived, plant] unless plant.archived?

      ActiveRecord::Base.transaction do
        plant.update!(archived_at: nil)
        plant.tasks.each do |task|
          task.update!(active: true)
          Tasks::Reschedule.new.call(task:)
        end
      end

      Success(plant)
    end
  end
end
