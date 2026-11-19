module Plants
  # Modifie une plante et son intervalle d'arrosage. Un nouvel intervalle recale l'échéance en cours depuis le dernier
  # arrosage.
  class Update
    include Dry::Monads[:result]

    def call(plant:, params:)
      form = PlantForm.new(params.to_h.merge(household: plant.household))
      return Failure[:invalid, form] unless form.valid?

      ActiveRecord::Base.transaction do
        attributes = form.plant_attributes
        attributes[:species_source] = (:user if attributes[:species]) if attributes[:species] != plant.species
        plant.update!(attributes)
        update_watering(plant.watering_task, form.watering_recurrence_config)
      end

      Success(plant)
    end

    private

    def update_watering(task, config)
      task.lock!
      return if task.recurrence_config == config

      task.update!(recurrence_config: config)
      Tasks::Reschedule.new.call(task:)
    end
  end
end
