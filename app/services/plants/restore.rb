module Plants
  # Restores an archived plant: its tasks resume, next occurrence recomputed from the last completion.
  class Restore
    include Dry::Monads[:result, :do]

    def call(plant:)
      ActiveRecord::Base.transaction do
        plant.lock!
        yield ensure_archived(plant)

        plant.update!(archived_at: nil)
        plant.tasks.each do |task|
          task.lock!
          task.update!(active: true)
          Tasks::Reschedule.new.call(task:)
        end
      end

      Success(plant)
    end

    private

    def ensure_archived(plant)
      plant.archived? ? Success(plant) : Failure[:not_archived, plant]
    end
  end
end
