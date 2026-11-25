module Plants
  # Adds a plant with its watering task (sliding recurrence) and its optional first photo, all or nothing: a photo
  # that cannot be read leaves no plant behind. The declared last watering goes into the log and is the starting
  # point of the first occurrence. A new location typed in the form (the household had none) is created with it.
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
        attributes = form.plant_attributes
        attributes[:location_id] = find_or_create_location(household, form).id if form.new_location?
        plant = household.plants.create!(
          **attributes,
          species_source: (:user if attributes[:species])
        )
        create_watering_task(plant, form, user)
        yield add_photo(plant, form) if form.photo.present?
        Success(plant)
      end
    end

    # The place typed for a first plant. Someone else may have created it meanwhile (house page, another first plant):
    # the existing one is kept, whatever its case, rather than failing.
    def find_or_create_location(household, form)
      name = form.new_location_attributes[:name]
      household.locations.find_by("lower(name) = ?", name.downcase) ||
        # A savepoint: a failed insert must not abort the transaction of the plant.
        Location.transaction(requires_new: true) { household.locations.create!(form.new_location_attributes) }
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      household.locations.find_by!("lower(name) = ?", name.downcase)
    end

    # The first photo is analysed right away, mostly to identify the species (the job starts after the commit).
    def request_first_analysis(plant, user)
      Plants::RequestAnalysis.new.call(plant:, user:) if plant.photos.any?
    end

    def add_photo(plant, form)
      Photos::Add.new.call(subject: plant, file: form.photo).or do |(_code, upload)|
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
      # Watered long ago: due within its tolerance, not missed at once (Tolerance.earliest).
      next_due_at = task.recurrence.next_due_at(last_completed_at: watered_at)
      task.occurrences.create!(due_at: task.due_within_tolerance(next_due_at))
    end
  end
end
