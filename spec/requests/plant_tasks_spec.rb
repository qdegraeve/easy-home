require "rails_helper"

RSpec.describe "Tâches d'une plante", type: :request do
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

  it "ajoute une tâche et l'affiche sur la fiche" do
    sign_in(user)

    post plant_tasks_path(plant), params: once_params

    expect(response).to redirect_to(plant_path(plant))
    follow_redirect!
    expect(response.body).to include("Tâche « Tailler » ajoutée.", "Une fois", "dans 14 j")
    expect(response.body).to include("Fait : Tailler (Citronnier)")
  end

  it "réaffiche le formulaire sans titre" do
    sign_in(user)

    post plant_tasks_path(plant), params: { task: once_params[:task].merge(title: " ") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Tâche doit être rempli(e)")
  end

  it "sur une plante archivée, refuse l'ajout et la modification, mais permet la suppression" do
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

  it "modifie une tâche répétée : prochaine fois et intervalle" do
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

  it "modifie puis supprime une tâche manuelle" do
    task = add_task
    sign_in(user)

    patch plant_task_path(plant, task), params: { task: { title: "Tailler court", due_on: "2026-12-01" } }
    expect(response).to redirect_to(plant_path(plant))
    expect(task.reload.pending_occurrence.due_at).to eq(Time.zone.parse("2026-12-01 00:00"))

    delete plant_task_path(plant, task)
    expect(response).to redirect_to(plant_path(plant))
    expect(Task.exists?(task.id)).to be(false)
  end

  it "ne laisse ni modifier ni supprimer la tâche d'arrosage par ici" do
    sign_in(user)

    get edit_plant_task_path(plant, plant.watering_task)
    expect(response).to have_http_status(:forbidden)
    delete plant_task_path(plant, plant.watering_task)
    expect(response).to have_http_status(:forbidden)
    expect(plant.reload.watering_task).to be_present
  end

  it "ne trouve pas la tâche d'une autre plante par l'URL de celle-ci" do
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

  describe "accueil" do
    it "ne montre ni les tâches d'un autre foyer de l'utilisateur, ni les tâches arrêtées" do
      other_household = create(:household_member, user:, role: :owner).household
      create(:plant, :watered, household: other_household, name: "Ailleurs", interval_days: 1)
      stopped = add_task(title: "Arrêtée", recurrence_type: "once", due_on: "2026-11-15")
      stopped.update!(active: false)
      sign_in(user)
      post household_selection_path(household)

      get root_path

      expect(response.body).not_to include("Ailleurs", "Arrêtée")
    end

    it "regroupe arrosages et autres tâches du jour (retards compris), sans les tâches à venir" do
      add_task(title: "Engrais", recurrence_type: "once", due_on: "2026-11-15")
      add_task(title: "Rempoter", recurrence_type: "once", due_on: "2026-12-15")
      plant.watering_task.pending_occurrence.update!(due_at: Time.zone.parse("2026-11-16 00:00"))
      sign_in(user)

      get root_path

      expect(response.body).to include("À faire aujourd&#39;hui · 2", "Arrosée : Citronnier")
      expect(response.body).to include("Fait : Engrais (Citronnier)")
      expect(response.body).to include("en retard de 1 j")
      expect(response.body).not_to include("Rempoter")
    end
  end
end
