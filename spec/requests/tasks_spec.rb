require "rails_helper"

# Tasks of the house itself (no subject) and the task sheet, for any task.
RSpec.describe "Tasks", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household, name: "Maison") }
  let(:user) { create(:household_member, household:, role: :member).user }
  let(:bins_params) do
    { task: { title: "Sortir la poubelle jaune", recurrence_type: "once", due_on: "2026-11-17",
              instructions: "Bac devant le portail." } }
  end

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }
  end

  def bins
    Tasks::Add.new.call(household:, params: bins_params[:task]).value!
  end

  it "adds a task of the current household, without subject, and lists it in the house tasks" do
    sign_in(user)

    post tasks_path, params: bins_params

    task = household.tasks.sole
    expect(task).to have_attributes(subject: nil, instructions: "Bac devant le portail.")
    expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-17 00:00"))
    expect(response).to redirect_to(house_tasks_path)
    follow_redirect!
    expect(response.parsed_body.text.squish).to include("Sortir la poubelle jaune demain")
  end

  it "keeps the typed values when the title is missing" do
    sign_in(user)

    post tasks_path, params: { task: bins_params[:task].merge(title: " ") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Bac devant le portail.")
    expect(Task.count).to eq(0)
  end

  it "shows the sheet with the instructions as plain text, line breaks kept" do
    task = bins
    task.update!(instructions: "<script>alert(1)</script>\nDeuxième ligne")
    sign_in(user)

    get task_path(task)

    expect(response.body).not_to include("<script>alert(1)</script>")
    expect(response.body).to include("&lt;script&gt;alert(1)&lt;/script&gt;\n<br />Deuxième ligne")
    expect(response.parsed_body.text.squish).to include("Tâche de la maison", "Prochaine fois : demain")
  end

  it "lists only the house tasks of the current household, with neither plants' tasks nor done one-offs" do
    bins
    plant = create(:plant, :watered, household:, name: "Citronnier")
    Tasks::Add.new.call(subject: plant, params: { title: "Tailler", due_on: "2026-11-20" })
    done = Tasks::Add.new.call(household:, params: { title: "Aérer la cave", due_on: "2026-11-16" }).value!
    Tasks::Complete.new.call(occurrence: done.pending_occurrence, user:)
    Tasks::Add.new.call(household: create(:household), params: { title: "Voisin", due_on: "2026-11-16" })
    sign_in(user)

    get house_tasks_path

    text = response.parsed_body.text.squish
    expect(text).to include("Sortir la poubelle jaune")
    expect(text).not_to include("Tailler", "Aérer la cave", "Voisin")
  end

  it "shows the house tasks on Maison once there is one, and offers what to add" do
    sign_in(user)
    get house_path
    expect(response.body).not_to include("Tâches de la maison")

    bins
    get house_path
    expect(response.parsed_body.text.squish).to include("Tâches de la maison 1 tâche")

    get new_house_item_path
    expect(response.parsed_body.text.squish).to include("Une plante", "Une tâche de la maison")
  end

  it "edits a house task back to its sheet, then deletes it back to the house tasks" do
    task = bins
    sign_in(user)

    patch task_path(task), params: { task: { title: "Sortir le bac jaune", due_on: "2026-11-18", instructions: "" } }
    expect(response).to redirect_to(task_path(task))
    expect(task.reload).to have_attributes(title: "Sortir le bac jaune", instructions: nil)

    delete task_path(task)
    expect(response).to redirect_to(house_tasks_path)
    expect(Task.exists?(task.id)).to be(false)
  end

  it "never takes the subject from the body: a task posted to /tasks belongs to the house" do
    other_plant = create(:plant, :watered, household: create(:household))
    sign_in(user)

    post tasks_path, params: bins_params.merge(plant_id: other_plant.id)

    expect(household.tasks.sole.subject).to be_nil
    expect(other_plant.tasks.count).to eq(1)
  end

  it "hides the house tasks from Maison and the list once the only one, a one-off, is done" do
    task = bins
    Tasks::Complete.new.call(occurrence: task.pending_occurrence, user:)
    sign_in(user)

    get house_path
    expect(response.body).not_to include("Tâches de la maison")
    get house_tasks_path
    expect(response.parsed_body.text.squish).to include("Aucune tâche de la maison pour l'instant.")
  end

  describe "the sheet" do
    it "does the task from the sheet and shows it done, in a browser" do
      task = Tasks::Add.new.call(household:, params: { title: "Aérer", recurrence_type: "sliding", due_on: "2026-11-16",
                                                       interval_days: "7" }).value!
      sign_in(user)

      post task_occurrence_completion_path(task.pending_occurrence), params: { from: "sheet" }

      expect(response).to redirect_to(task_path(task))
      follow_redirect!
      text = response.parsed_body.text.squish
      expect(text).to include("Aérer noté.", "Fait aujourd'hui", "Prochaine fois : dans 7 j")
      expect(response.body).not_to include("Marquer comme fait : Aérer")
    end

    it "is closed after Fait in the Android app, the screen under it showing the toast" do
      task = bins
      sign_in(user)
      app = { "User-Agent" => "Mozilla/5.0 (Linux; Android 17) Hotwire Native Android" }

      post task_occurrence_completion_path(task.pending_occurrence), params: { from: "sheet" }, headers: app

      expect(response).to redirect_to(%r{/recede_historical_location})
      expect(flash[:notice]).to eq("Sortir la poubelle jaune noté.")
    end

    it "postpones from the sheet, back to it" do
      task = Tasks::Add.new.call(household:, params: { title: "Aérer", due_on: "2026-11-16" }).value!
      sign_in(user)

      post task_occurrence_postponement_path(task.pending_occurrence), params: { from: "sheet" }

      expect(response).to redirect_to(task_path(task))
      expect(task.reload.pending_occurrence.due_at.to_date).to eq(Date.new(2026, 11, 17))
    end

    it "shows a watering without edit, and the task of an archived plant without due date nor edit" do
      plant = create(:plant, :watered, household:, name: "Citronnier")
      pruning = Tasks::Add.new.call(subject: plant, params: { title: "Tailler", due_on: "2026-11-20" }).value!
      sign_in(user)

      get task_path(plant.watering_task)
      expect(response.body).not_to include("Modifier", "Ajouter le comment faire")

      Plants::Archive.new.call(plant:)
      get task_path(pruning)
      expect(response.parsed_body.text.squish).to include("Plus d'échéance.")
      expect(response.body).not_to include("Modifier")
    end
  end

  describe "access denied" do
    let(:task) { bins }

    it "answers 404 to a user of another household on every action, without changing anything" do
      task
      sign_in(create(:user, :with_household))

      get task_path(task)
      expect(response).to have_http_status(:not_found)
      patch task_path(task), params: { task: { title: "X", due_on: "2026-12-01" } }
      expect(response).to have_http_status(:not_found)
      delete task_path(task)
      expect(response).to have_http_status(:not_found)
      expect(task.reload.title).to eq("Sortir la poubelle jaune")
    end

    it "forbids a guest to see, add or list the house tasks" do
      task
      sign_in(create(:household_member, household:, role: :guest).user)

      get task_path(task)
      expect(response).to have_http_status(:not_found)
      get new_task_path
      expect(response).to have_http_status(:forbidden)
      post tasks_path, params: bins_params
      expect(response).to have_http_status(:forbidden)
      get house_tasks_path
      expect(response).to have_http_status(:forbidden)
      get new_house_item_path
      expect(response).to have_http_status(:forbidden)
      expect(Task.count).to eq(1)
    end
  end
end
