# What the household maintains (ADR 0016): the list (Maison → Équipements), the page of one (its tasks and what is
# good to know, its history), and its plain CRUD. Deleting one deletes its tasks and their history.
class EquipmentController < ApplicationController
  TABS = %w[care photos history].freeze

  def index
    @household = current_household
    return redirect_to(new_household_path) unless @household

    authorize @household, :manage?
    @equipment = policy_scope(Equipment).where(household: @household).order(:name).to_a
    # The next due date of each, in one query.
    @next_due = Task.to_do.where(subject: @equipment).group(:subject_id).minimum("task_occurrences.due_at")
  end

  def show
    @equipment = find_equipment
    @tab = params[:tab].presence_in(TABS) || "care"
    @tasks = @equipment.tasks.to_do.includes(:pending_occurrence).order("task_occurrences.due_at", :id)
    @on_demand_tasks = @equipment.tasks.active.on_demand.order(:title).to_a
    @last_done_at = Task.last_done_at_by_id(@on_demand_tasks)
    @history = SubjectHistoryQuery.new.call(subject: @equipment) if @tab == "history"
    @photos = @equipment.photos.with_attached_image.to_a if @tab == "photos"
    @photos_count = @equipment.photos.count
    @face = @equipment.face
  end

  def new
    household = current_household
    return redirect_to(new_household_path) unless household

    @equipment = household.equipment.build(kind: params[:kind].presence_in(Catalogue.equipment_kind_keys))
    authorize @equipment
  end

  def create
    household = current_household
    return redirect_to(new_household_path) unless household

    @equipment = household.equipment.build(equipment_params)
    authorize @equipment
    if @equipment.save
      # Next: its suggested upkeep tasks, when its kind has some.
      next_path = @equipment.kind_info.suggestion_keys.any? ? new_equipment_suggestions_path(@equipment) : @equipment
      redirect_to next_path, notice: t(".success", name: @equipment.name)
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @equipment = find_equipment
  end

  def update
    @equipment = find_equipment
    if @equipment.update(equipment_params)
      redirect_to @equipment, notice: t(".success", name: @equipment.name)
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    equipment = find_equipment
    equipment.destroy!
    redirect_to equipment_index_path, notice: t(".success", name: equipment.name), status: :see_other
  end

  private

  def find_equipment
    policy_scope(Equipment).find(params[:id]).tap { |equipment| authorize equipment }
  end

  def equipment_params
    params.expect(equipment: [ :kind, :name, :notes ])
  end
end
