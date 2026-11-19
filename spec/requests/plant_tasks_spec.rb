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
    expect(response.body).to include("Tâche « Tailler » ajoutée.", "Tailler", "Une fois", "dans 14 j", "Fait : Tailler (Citronnier)")
  end

  it "réaffiche le formulaire sans titre" do
    sign_in(user)

    post plant_tasks_path(plant), params: { task: once_params[:task].merge(title: " ") }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Tâche doit être rempli(e)")
  end

  it "refuse d'ajouter une tâche à une plante archivée" do
    plant.update!(archived_at: Time.current)
    sign_in(user)

    post plant_tasks_path(plant), params: once_params

    expect(response).to redirect_to(plant_path(plant))
    expect(flash[:alert]).to include("restaurez-la")
    expect(plant.tasks.count).to eq(1)
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

  describe "accès refusé" do
    def requests(task)
      {
        "formulaire d'ajout" => -> { get new_plant_task_path(plant) },
        "ajout" => -> { post plant_tasks_path(plant), params: once_params },
        "formulaire de modification" => -> { get edit_plant_task_path(plant, task) },
        "modification" => -> { patch plant_task_path(plant, task), params: { task: { title: "X", due_on: "2026-12-01" } } },
        "suppression" => -> { delete plant_task_path(plant, task) }
      }
    end

    [ [ "un invité du foyer", :guest ], [ "un autre foyer", :other ] ].each do |label, who|
      it "répond 404 à #{label} sur chaque action, sans rien modifier" do
        task = add_task
        intruder = who == :guest ? create(:household_member, household:, role: :guest).user : create(:user, :with_household)
        sign_in(intruder)

        requests(task).each do |action, request|
          request.call
          expect(response).to have_http_status(:not_found), "#{action} : #{response.status}"
        end
        expect(task.reload.title).to eq("Tailler")
        expect(plant.tasks.count).to eq(2)
      end
    end
  end

  describe "accueil" do
    it "regroupe arrosages et autres tâches du jour (retards compris), sans les tâches à venir" do
      add_task(title: "Engrais", recurrence_type: "once", due_on: "2026-11-15")
      add_task(title: "Rempoter", recurrence_type: "once", due_on: "2026-12-15")
      plant.watering_task.pending_occurrence.update!(due_at: Time.zone.parse("2026-11-16 00:00"))
      sign_in(user)

      get root_path

      expect(response.body).to include("À faire aujourd&#39;hui · 2", "Arrosée : Citronnier", "Fait : Engrais (Citronnier)")
      expect(response.body).to include("en retard de 1 j")
      expect(response.body).not_to include("Rempoter")
    end
  end
end
