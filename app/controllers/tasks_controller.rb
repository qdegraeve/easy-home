# Manual tasks, of a plant (fertilizer, pruning…) or of the house itself (bins…), and the task sheet: what to do,
# how ("Comment faire"), when, with "Fait" and "Reporter". The subject comes from the URL only
# (plants/:plant_id/tasks), through policy_scope; a task without one belongs to the current household.
class TasksController < ApplicationController
  SUBJECTS = { plant_id: Plant }.freeze

  before_action :load_target, only: [ :new, :create ]

  def show
    @task = find_task
    @occurrence = @task.pending_occurrence
    @last_done_at = @task.occurrences.done.maximum(:completed_at)
  end

  # A suggestion of the catalogue (?suggestion=bins.yellow) prefills the form; unknown, it is ignored.
  def new
    suggestion = Catalogue.suggestion(params[:suggestion])
    @form = suggestion ? TaskForm.from_suggestion(suggestion) : TaskForm.new(due_on: Time.zone.today)
    @suggestions = suggestions
  end

  def create
    result = Tasks::Add.new.call(subject: @subject, household: @household, params: task_params)

    if result.success?
      redirect_to back_path(result.value!), notice: t(".success", title: result.value!.title)
    else
      code, @form = result.failure
      return forbidden if code == :subject_archived # the subject was archived meanwhile

      @suggestions = suggestions
      render :new, status: :unprocessable_content
    end
  end

  def edit
    @task = find_task(:update?)
    @form = TaskForm.from(@task)
  end

  # Back to the sheet the edit was opened from, which shows the changes.
  def update
    @task = find_task(:update?)
    result = Tasks::Update.new.call(task: @task, params: task_params)

    if result.success?
      redirect_to task_path(@task), notice: t(".success", title: @task.title)
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

  # The subject from the path (never from the body or the query), and the household the new task belongs to.
  def load_target
    key, model = SUBJECTS.find { |param, _| request.path_parameters.key?(param) }
    @subject = policy_scope(model).find(request.path_parameters[key]) if key
    @household = @subject&.household || current_household
    return redirect_to(new_household_path) unless @household

    authorize Task.new(household: @household, subject: @subject), :create?
  end

  # The suggestions of a task of the house, but for those already added (none for a plant).
  def suggestions
    return [] if @subject

    used = @household.tasks.without_subject.active.where.not(suggestion_key: nil).pluck(:suggestion_key)
    Catalogue.household_suggestions(existing_keys: used)
  end

  def find_task(query = :show?)
    policy_scope(Task).find(params[:id]).tap { |task| authorize task, query }
  end

  # The subject's page, or the list of the house tasks.
  def back_path(task)
    task.subject ? polymorphic_path(task.subject) : house_tasks_path
  end

  def task_params
    params.expect(
      task: [ :title, :recurrence_type, :due_on, :interval_days, :interval, :unit, :critical, :instructions,
              :suggestion_key ]
    )
  end
end
