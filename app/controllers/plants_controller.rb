class PlantsController < ApplicationController
  # The plants of the household by location, with their next watering; archived ones apart (Maison > Plantes).
  def index
    @household = current_household
    return redirect_to(new_household_path) unless @household

    authorize @household, :show?
    plants = policy_scope(Plant).where(household: @household).order(:name)
    @plants = plants.active.includes(:location, :analyses, watering_task: :pending_occurrence)
    @archived_plants = plants.archived
  end

  TABS = %w[care photos history].freeze

  def show
    @plant = find_plant
    @tab = params[:tab].presence_in(TABS) || "care"
    @watering_task = @plant.watering_task
    @photos = @plant.photos.with_attached_image
    @analyses = @plant.analyses.recent_first
      .includes(:photos, questions: { photo: { image_attachment: :blob } })
      .limit(10)
    @other_tasks = @plant.tasks.active.where.not(id: @watering_task)
      .includes(:pending_occurrence).select(&:pending_occurrence).sort_by { |task| task.pending_occurrence.due_at }
    occurrences = TaskOccurrence.done.where(task: @plant.tasks)
    # What was done, postponed (Tasks::Postpone) or missed (Tasks::MarkMissed).
    @journal = SubjectHistoryQuery.new.call(subject: @plant)
    @last_watering = occurrences.where(task: @watering_task).order(completed_at: :desc, id: :desc).first
    @done_today_task_ids = occurrences.where(completed_at: Time.zone.today.all_day).distinct.pluck(:task_id)
  end

  def new
    household = current_household
    return redirect_to(new_household_path) unless household

    authorize Plant.new(household:)
    # A common rhythm to start with: the analysis of the photo proposes the right one (UX review #36).
    @form = PlantForm.new(household:, watering_interval_days: PlantForm::DEFAULT_WATERING_DAYS)
  end

  def create
    household = current_household
    return redirect_to(new_household_path) unless household

    authorize Plant.new(household:)
    result = Plants::Add.new.call(household:, user: Current.user, params: new_plant_params)

    if result.success?
      plant = result.value!
      redirect_to plant, notice: t(".success", name: plant.name)
    else
      _code, @form = result.failure
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @plant = find_plant
    @form = PlantForm.from(@plant)
  end

  def update
    @plant = find_plant
    result = Plants::Update.new.call(plant: @plant, params: plant_params)

    if result.success?
      redirect_to @plant, notice: t(".success")
    else
      _code, @form = result.failure
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    plant = find_plant
    plant.destroy!
    redirect_to plants_path, notice: t(".success", name: plant.name), status: :see_other
  end

  private

  def find_plant
    policy_scope(Plant).find(params[:id]).tap { |plant| authorize plant }
  end

  PLANT_PARAMS = [ :name, :species, :location_id, :watering_interval_days, :last_watered_on, :photo ].freeze
  # Only when adding: the place of a first plant, created with it.
  NEW_LOCATION_PARAMS = [ :new_location_name, :new_location_exposure, :new_location_rain_exposed ].freeze

  def plant_params
    params.expect(plant: PLANT_PARAMS)
  end

  def new_plant_params
    params.expect(plant: PLANT_PARAMS + NEW_LOCATION_PARAMS)
  end
end
