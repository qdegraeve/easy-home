module Plants
  # Tâches manuelles d'une plante (engrais, taille…).
  class TasksController < ApplicationController
    before_action :set_plant

    def new
      authorize Task.new(household: @plant.household, subject: @plant)
      @form = TaskForm.new
    end

    def create
      authorize Task.new(household: @plant.household, subject: @plant)
      result = Tasks::Add.new.call(subject: @plant, params: task_params)

      if result.success?
        redirect_to @plant, notice: t(".success", title: result.value!.title)
      else
        code, @form = result.failure
        return redirect_to(@plant, alert: t(".subject_archived")) if code == :subject_archived

        render :new, status: :unprocessable_content
      end
    end

    def edit
      @task = find_task
      @form = TaskForm.from(@task)
    end

    def update
      @task = find_task
      result = Tasks::Update.new.call(task: @task, params: task_params)

      if result.success?
        redirect_to @plant, notice: t(".success", title: @task.title)
      else
        _code, @form = result.failure
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      task = find_task
      task.destroy!
      redirect_to @plant, notice: t(".success", title: task.title), status: :see_other
    end

    private

    def set_plant
      @plant = policy_scope(Plant).find(params[:plant_id])
    end

    def find_task
      policy_scope(Task).where(subject: @plant).find(params[:id]).tap { |task| authorize task }
    end

    def task_params
      params.expect(task: [ :title, :recurrence_type, :due_on, :interval_days ])
    end
  end
end
