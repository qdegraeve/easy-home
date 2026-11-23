require "rails_helper"

RSpec.describe "Equipment", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household, name: "Maison") }
  let(:user) { create(:household_member, household:, role: :member).user }

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }
  end

  it "adds an equipment named after its kind, then shows it with its notes as plain text" do
    sign_in(user)

    post equipment_index_path,
      params: { equipment: { kind: "dishwasher", name: "", notes: "<b>Filtre</b> réf. 42\nSel" } }

    equipment = household.equipment.sole
    expect(equipment).to have_attributes(kind: "dishwasher", name: "Lave-vaisselle")
    expect(response).to redirect_to(equipment_path(equipment))
    follow_redirect!
    expect(response.body).to include("&lt;b&gt;Filtre&lt;/b&gt; réf. 42\n<br />Sel")
    expect(response.parsed_body.text.squish).to include("Lave-vaisselle", "Aucune tâche d'entretien")
  end

  it "keeps the typed values when the kind is missing" do
    sign_in(user)

    post equipment_index_path, params: { equipment: { kind: "", name: "Clim" } }

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include('value="Clim"')
    expect(Equipment.count).to eq(0)
  end

  it "lists its tasks with their rhythm, adds one from its page, and shows its history" do
    equipment = create(:equipment, household:, kind: "dishwasher", name: "Lave-vaisselle")
    sign_in(user)

    post equipment_tasks_path(equipment), params: { task: { title: "Nettoyer le filtre", recurrence_type: "sliding",
                                                            due_on: "2026-11-16", interval: "1", unit: "months" } }
    task = equipment.tasks.sole
    expect(response).to redirect_to(equipment_path(equipment))

    follow_redirect!
    expect(response.parsed_body.text.squish).to include("Nettoyer le filtre Tous les mois · aujourd'hui")
    get root_path
    expect(response.parsed_body.text.squish).to include("Nettoyer le filtre Lave-vaisselle · aujourd'hui")

    Tasks::Complete.new.call(occurrence: task.pending_occurrence, user:)
    get equipment_path(equipment, tab: "history")
    expect(response.parsed_body.text.squish).to include("Nettoyer le filtre Lave-vaisselle · par vous")
  end

  it "lists the equipment of the household on Maison and on its page, not another household's" do
    create(:equipment, household:, name: "Piscine")
    create(:equipment, name: "Voisin")
    sign_in(user)

    get house_path
    expect(response.parsed_body.text.squish).to include("Équipements 1 équipement")
    get equipment_index_path
    expect(response.parsed_body.text.squish).to include("Piscine")
    expect(response.body).not_to include("Voisin")
  end

  it "edits it, kind included, then deletes it with its tasks and their history" do
    equipment = create(:equipment, household:, kind: "dishwasher")
    task = Tasks::Add.new.call(subject: equipment, params: { title: "Filtre", due_on: "2026-11-16" }).value!
    sign_in(user)

    patch equipment_path(equipment), params: { equipment: { kind: "washing_machine", name: "Lave-linge du bas" } }
    expect(equipment.reload).to have_attributes(kind: "washing_machine", name: "Lave-linge du bas")

    delete equipment_path(equipment)
    expect(response).to redirect_to(equipment_index_path)
    expect([ Equipment.count, Task.where(id: task.id).count, TaskOccurrence.where(task_id: task.id).count ])
      .to eq([ 0, 0, 0 ])
  end

  describe "access denied" do
    let(:equipment) { create(:equipment, household:) }

    {
      "a guest of the household" => ->(household) { create(:household_member, household:, role: :guest).user },
      "a user of another household" => ->(_household) { create(:user, :with_household) }
    }.each do |label, intruder|
      it "answers 404 to #{label} on its page, its edit, its tasks and its deletion, changing nothing" do
        equipment
        sign_in(instance_exec(household, &intruder))

        get equipment_path(equipment)
        expect(response).to have_http_status(:not_found)
        patch equipment_path(equipment), params: { equipment: { name: "X" } }
        expect(response).to have_http_status(:not_found)
        post equipment_tasks_path(equipment), params: { task: { title: "X", due_on: "2026-11-16" } }
        expect(response).to have_http_status(:not_found)
        delete equipment_path(equipment)
        expect(response).to have_http_status(:not_found)
        expect(equipment.reload.name).not_to eq("X")
        expect(equipment.tasks).to be_empty
      end
    end

    it "forbids a guest to list or add equipment" do
      sign_in(create(:household_member, household:, role: :guest).user)

      get equipment_index_path
      expect(response).to have_http_status(:forbidden)
      post equipment_index_path, params: { equipment: { kind: "pool" } }
      expect(response).to have_http_status(:forbidden)
      expect(Equipment.count).to eq(0)
    end
  end
end
