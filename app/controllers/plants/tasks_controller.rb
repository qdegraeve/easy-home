module Plants
  # Manual tasks of a plant (fertilizer, pruning…).
  class TasksController < ApplicationController
    def new
      @plant = find_plant
      authorize Task.new(household: @plant.household, subject: @plant)
      @form = TaskForm.new(due_on: Time.zone.today)
    end

    def create
      @plant = find_plant
      authorize Task.new(household: @plant.household, subject: @plant)
      result = Tasks::Add.new.call(subject: @plant, params: task_params)

      if result.success?
        redirect_to @plant, notice: t(".success", title: result.value!.title)
      else
        _code, @form = result.failure
        render :new, status: :unprocessable_content
      end
    end

    def edit
      @plant = find_plant
      @task = find_task(@plant)
      @form = TaskForm.from(@task)
    end

    def update
      @plant = find_plant
      @task = find_task(@plant)
      result = Tasks::Update.new.call(task: @task, params: task_params)

      if result.success?
        redirect_to @plant, notice: t(".success", title: @task.title)
      else
        _code, @form = result.failure
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      plant = find_plant
      task = find_task(plant)
      task.destroy!
      redirect_to plant, notice: t(".success", title: task.title), status: :see_other
    end

    private

    def find_plant
      policy_scope(Plant).find(params[:plant_id])
    end

    def find_task(plant)
      policy_scope(Task).where(subject: plant).find(params[:id]).tap { |task| authorize task }
    end

    def task_params
      params.expect(task: [ :title, :recurrence_type, :due_on, :interval_days, :critical ])
    end
  end
end
