module Plants
  # Adds a plant with its watering task (sliding recurrence) and its optional first photo, all or nothing: a photo
  # that cannot be read leaves no plant behind. The declared last watering goes into the log and is the starting
  # point of the first occurrence.
  class Add
    include Dry::Monads[:result, :do]

    def call(household:, user:, params:)
      form = yield validate(household, params)
      plant = yield create_plant(household, user, form)
      request_first_analysis(plant, user)

      Success(plant)
    end

    private

    def validate(household, params)
      form = PlantForm.new(params.to_h.merge(household:))
      form.valid?(:create) ? Success(form) : Failure[:invalid, form]
    end

    def create_plant(household, user, form)
      ActiveRecord::Base.transaction do
        plant = household.plants.create!(
          **form.plant_attributes,
          species_source: (:user if form.plant_attributes[:species])
        )
        create_watering_task(plant, form, user)
        yield add_photo(plant, form) if form.photo.present?
        Success(plant)
      end
    end

    # The first photo is analysed right away, mostly to identify the species (the job starts after the commit).
    def request_first_analysis(plant, user)
      Plants::RequestAnalysis.new.call(plant:, user:) if plant.photos.any?
    end

    def add_photo(plant, form)
      Photos::Add.new.call(plant:, file: form.photo).or do |(_code, upload)|
        upload.errors.messages_for(:file).each { |message| form.errors.add(:photo, message) }
        Failure[:invalid, form]
      end
    end

    def create_watering_task(plant, form, user)
      task = plant.tasks.create!(
        household: plant.household,
        title: I18n.t("plants.watering_task_title"),
        template_key: Plant::WATERING_TEMPLATE_KEY,
        recurrence_type: :sliding,
        recurrence_config: form.watering_recurrence_config
      )
      watered_at = (form.last_watered_on || Time.zone.today).in_time_zone
      task.occurrences.create!(status: :done, due_at: watered_at, completed_at: watered_at, completed_by: user)
      task.occurrences.create!(due_at: task.recurrence.next_due_at(last_completed_at: watered_at))
    end
  end
end
