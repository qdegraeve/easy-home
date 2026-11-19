module Plants
  # Ajoute une plante avec sa tâche d'arrosage (récurrence glissante). Le dernier arrosage déclaré entre au journal et
  # sert de point de départ à la première échéance.
  class Add
    include Dry::Monads[:result]

    def call(household:, user:, params:)
      form = PlantForm.new(params.to_h.merge(household:))
      return Failure[:invalid, form] unless form.valid?(:create)

      plant = ActiveRecord::Base.transaction do
        plant = household.plants.create!(
          **form.plant_attributes,
          species_source: (:user if form.plant_attributes[:species])
        )
        create_watering_task(plant, form, user)
        plant
      end

      Success(plant)
    end

    private

    def create_watering_task(plant, form, user)
      task = plant.tasks.create!(
        household: plant.household,
        title: I18n.t("plants.watering_task_title"),
        template_key: Plant::WATERING_TEMPLATE_KEY,
        recurrence_type: :sliding,
        recurrence_config: form.watering_recurrence_config
      )
      watered_at = form.last_watered_on.in_time_zone
      task.occurrences.create!(status: :done, due_at: watered_at, completed_at: watered_at, completed_by: user)
      task.occurrences.create!(due_at: task.recurrence.next_due_at(last_completed_at: watered_at))
    end
  end
end
