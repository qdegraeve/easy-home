# Manual tasks, of a plant (fertilizer, pruning…) or of the house itself (bins…), and the task sheet: what to do,
# how ("Comment faire"), when, with "Fait" and "Reporter". The subject comes from the route (plants/:plant_id/tasks),
# through policy_scope; a task without one belongs to the current household.
class TasksController < ApplicationController
  SUBJECTS = { plant_id: Plant }.freeze

  def show
    @task = find_task
    @occurrence = @task.pending_occurrence
    @last_done_at = @task.occurrences.done.maximum(:completed_at)
  end

  def new
    @subject = find_subject
    return redirect_to(new_household_path) unless (household = target_household)

    authorize Task.new(household:, subject: @subject)
    @form = TaskForm.new(due_on: Time.zone.today)
  end

  def create
    @subject = find_subject
    return redirect_to(new_household_path) unless (household = target_household)

    authorize Task.new(household:, subject: @subject)
    result = Tasks::Add.new.call(subject: @subject, household:, params: task_params)

    if result.success?
      redirect_to back_path(result.value!), notice: t(".success", title: result.value!.title)
    else
      _code, @form = result.failure
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @task = find_task(:update?)
    @form = TaskForm.from(@task)
  end

  def update
    @task = find_task(:update?)
    result = Tasks::Update.new.call(task: @task, params: task_params)

    if result.success?
      redirect_to back_path(@task), notice: t(".success", title: @task.title)
    else
      _code, @form = result.failure
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    task = find_task(:destroy?)
    task.destroy!
    redirect_to back_path(task), notice: t(".success", title: task.title), status: :see_other
  end

  private

  def find_subject
    key, model = SUBJECTS.find { |param, _| params[param] }
    policy_scope(model).find(params[key]) if key
  end

  def target_household
    @subject&.household || current_household
  end

  def find_task(query = :show?)
    policy_scope(Task).find(params[:id]).tap { |task| authorize task, query }
  end

  # The subject's page, or the list of the house tasks.
  def back_path(task)
    task.subject ? polymorphic_path(task.subject) : house_tasks_path
  end

  def task_params
    params.expect(task: [ :title, :recurrence_type, :due_on, :interval_days, :critical, :instructions ])
  end
end
