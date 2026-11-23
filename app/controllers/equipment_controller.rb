# What the household maintains (ADR 0016): the list (Maison → Équipements), the page of one (its tasks and what is
# good to know, its history), and its plain CRUD. Deleting one deletes its tasks and their history.
class EquipmentController < ApplicationController
  TABS = %w[care history].freeze

  def index
    @household = current_household
    return redirect_to(new_household_path) unless @household

    authorize @household, :update?
    @equipment = policy_scope(Equipment).where(household: @household).order(:name)
      .includes(tasks: :pending_occurrence)
  end

  def show
    @equipment = find_equipment
    @tab = params[:tab].presence_in(TABS) || "care"
    @tasks = @equipment.tasks.active.includes(:pending_occurrence).select(&:pending_occurrence)
      .sort_by { |task| [ task.pending_occurrence.due_at, task.id ] }
    @history = TaskOccurrence.where(task: @equipment.tasks, status: %i[done missed postponed])
      .includes(:completed_by, task: :subject).order(completed_at: :desc, id: :desc).limit(30)
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
      redirect_to @equipment, notice: t(".success", name: @equipment.name)
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
