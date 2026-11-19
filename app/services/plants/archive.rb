module Plants
  # Archives a plant (dead, given away…): no more occurrences or reminders, but its page and log remain.
  class Archive
    include Dry::Monads[:result, :do]

    def call(plant:)
      ActiveRecord::Base.transaction do
        plant.lock!
        yield ensure_active(plant)

        plant.update!(archived_at: Time.current)
        plant.tasks.each do |task|
          task.lock!
          task.update!(active: false)
          task.occurrences.pending.delete_all
        end
      end

      Success(plant)
    end

    private

    def ensure_active(plant)
      plant.archived? ? Failure[:already_archived, plant] : Success(plant)
    end
  end
end
