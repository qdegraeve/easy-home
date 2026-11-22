require "rails_helper"

RSpec.describe "Plant tasks", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household) }
  let(:user) { create(:household_member, household:, role: :member).user }
  let(:plant) { create(:plant, :watered, household:, name: "Citronnier") }
  let(:once_params) { { task: { title: "Tailler", recurrence_type: "once", due_on: "2026-11-30" } } }

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }
  end

  def add_task(params = once_params[:task])
    Tasks::Add.new.call(subject: plant, params:).value!
  end

  it "adds a task and shows it on the plant page" do
    sign_in(user)

    post plant_tasks_path(plant), params: once_params

    expect(response).to redirect_to(plant_path(plant))
    follow_redirect!
    expect(response.body).to include("Tâche « Tailler » ajoutée.", "Une fois", "dans 14 j")
    expect(response.body).to include("Marquer comme fait : Tailler (Citronnier)")
  end

  it "renders the form again without a title" do
    sign_in(user)

    post plant_tasks_path(plant), params: { task: once_params[:task].merge(title: " ") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Tâche doit être rempli(e)")
  end

  it "on an archived plant, forbids adding and editing, but allows deleting" do
    task = add_task
    Plants::Archive.new.call(plant:)
    sign_in(user)

    get new_plant_task_path(plant)
    expect(response).to have_http_status(:forbidden)
    post plant_tasks_path(plant), params: once_params
    expect(response).to have_http_status(:forbidden)
    get edit_plant_task_path(plant, task)
    expect(response).to have_http_status(:forbidden)
    patch plant_task_path(plant, task), params: { task: { title: "X", due_on: "2026-12-01" } }
    expect(response).to have_http_status(:forbidden)
    expect(plant.tasks.count).to eq(2)

    delete plant_task_path(plant, task)
    expect(response).to redirect_to(plant_path(plant))
    expect(plant.tasks.count).to eq(1)
  end

  it "edits a repeating task: next date and interval" do
    task = add_task(title: "Engrais", recurrence_type: "sliding", due_on: "2026-11-20", interval_days: "14")
    sign_in(user)

    get edit_plant_task_path(plant, task)
    expect(response.body).to include("Prochaine fois", 'value="2026-11-20"', 'value="14"')
    expect(response.body).not_to include("Une seule fois")

    patch plant_task_path(plant, task),
      params: { task: { title: "Engrais", due_on: "2026-11-22", interval_days: "21" } }

    expect(task.reload.recurrence.interval_days).to eq(21)
    expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-22 00:00"))
  end

  it "marks a task as one that must not be missed, and back" do
    task = add_task
    sign_in(user)

    patch plant_task_path(plant, task), params: { task: { title: "Tailler", due_on: "2026-12-01", critical: "1" } }
    expect(task.reload).to be_critical
    get edit_plant_task_path(plant, task)
    expect(response.parsed_body.at_css("input[type=checkbox][name='task[critical]']")["checked"]).to eq("checked")

    patch plant_task_path(plant, task), params: { task: { title: "Tailler", due_on: "2026-12-01", critical: "0" } }
    expect(task.reload).to be_flexible
  end

  it "edits then deletes a manual task" do
    task = add_task
    sign_in(user)

    patch plant_task_path(plant, task), params: { task: { title: "Tailler court", due_on: "2026-12-01" } }
    expect(response).to redirect_to(plant_path(plant))
    expect(task.reload.pending_occurrence.due_at).to eq(Time.zone.parse("2026-12-01 00:00"))

    delete plant_task_path(plant, task)
    expect(response).to redirect_to(plant_path(plant))
    expect(Task.exists?(task.id)).to be(false)
  end

  it "lets neither edit nor delete the watering task from here" do
    sign_in(user)

    get edit_plant_task_path(plant, plant.watering_task)
    expect(response).to have_http_status(:forbidden)
    delete plant_task_path(plant, plant.watering_task)
    expect(response).to have_http_status(:forbidden)
    expect(plant.reload.watering_task).to be_present
  end

  it "does not find the task of another plant through this plant's URL" do
    other_plant = create(:plant, :watered, household:)
    task = add_task
    sign_in(user)

    delete plant_task_path(other_plant, task)

    expect(response).to have_http_status(:not_found)
    expect(Task.exists?(task.id)).to be(true)
  end

  describe "access denied" do
    let(:task) { add_task }
    let(:requests) do
      {
        "new form" => -> { get new_plant_task_path(plant) },
        "create" => -> { post plant_tasks_path(plant), params: once_params },
        "edit form" => -> { get edit_plant_task_path(plant, task) },
        "update" => -> { patch plant_task_path(plant, task), params: { task: { title: "X", due_on: "2026-12-01" } } },
        "destroy" => -> { delete plant_task_path(plant, task) }
      }
    end

    {
      "a guest of the household" => -> { create(:household_member, household:, role: :guest).user },
      "a user of another household" => -> { create(:user, :with_household) }
    }.each do |intruder_label, intruder|
      [ "new form", "create", "edit form", "update", "destroy" ].each do |action|
        it "answers 404 to #{intruder_label} on #{action}, without changing anything" do
          task
          sign_in(instance_exec(&intruder))

          instance_exec(&requests.fetch(action))

          expect(response).to have_http_status(:not_found)
          expect(task.reload.title).to eq("Tailler")
          expect(plant.tasks.count).to eq(2)
        end
      end
    end
  end

  describe "home page" do
    it "shows neither tasks of another household of the user, nor stopped tasks" do
      other_household = create(:household_member, user:, role: :owner).household
      create(:plant, :watered, household: other_household, name: "Ailleurs", interval_days: 1)
      stopped = add_task(title: "Arrêtée", recurrence_type: "once", due_on: "2026-11-15")
      stopped.update!(active: false)
      sign_in(user)
      post household_selection_path(household)

      get root_path

      expect(response.body).not_to include("Ailleurs", "Arrêtée")
    end

    it "groups waterings and other tasks of the day (late ones included), without upcoming tasks" do
      add_task(title: "Engrais", recurrence_type: "once", due_on: "2026-11-15")
      add_task(title: "Rempoter", recurrence_type: "once", due_on: "2026-12-15")
      plant.watering_task.pending_occurrence.update!(due_at: Time.zone.parse("2026-11-16 00:00"))
      sign_in(user)

      get root_path

      expect(response.body).to include("À faire aujourd&#39;hui · 2", "Marquer comme arrosée : Citronnier")
      expect(response.body).to include("Marquer comme fait : Engrais (Citronnier)")
      expect(response.body).to include("prévu hier")
      expect(response.body).not_to include("Rempoter")
    end
  end
end
