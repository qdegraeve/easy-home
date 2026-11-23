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

  it "edits then deletes a house task, back to the house tasks" do
    task = bins
    sign_in(user)

    patch task_path(task), params: { task: { title: "Sortir le bac jaune", due_on: "2026-11-18", instructions: "" } }
    expect(response).to redirect_to(house_tasks_path)
    expect(task.reload).to have_attributes(title: "Sortir le bac jaune", instructions: nil)

    delete task_path(task)
    expect(response).to redirect_to(house_tasks_path)
    expect(Task.exists?(task.id)).to be(false)
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
