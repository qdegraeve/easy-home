class PlantsController < ApplicationController
  def show
    @plant = find_plant
    @watering_task = @plant.watering_task
    @other_tasks = @plant.tasks.active.where.not(id: @watering_task)
      .includes(:pending_occurrence).select(&:pending_occurrence).sort_by { |task| task.pending_occurrence.due_at }
    occurrences = TaskOccurrence.done.where(task: @plant.tasks)
    @journal = occurrences.includes(:task).order(completed_at: :desc).limit(30)
    @last_watered_at = occurrences.where(task: @watering_task).maximum(:completed_at)
    @done_today_task_ids = occurrences.where(completed_at: Time.zone.today.all_day).distinct.pluck(:task_id)
  end

  def new
    household = current_household
    return redirect_to(new_household_path) unless household

    authorize Plant.new(household:)
    @form = PlantForm.new(household:)
  end

  def create
    household = current_household
    return redirect_to(new_household_path) unless household

    authorize Plant.new(household:)
    result = Plants::Add.new.call(household:, user: Current.user, params: plant_params)

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
    redirect_to root_path, notice: t(".success", name: plant.name), status: :see_other
  end

  private

  def find_plant
    policy_scope(Plant).find(params[:id]).tap { |plant| authorize plant }
  end

  def plant_params
    params.expect(plant: [ :name, :species, :location_id, :watering_interval_days, :last_watered_on ])
  end
end
