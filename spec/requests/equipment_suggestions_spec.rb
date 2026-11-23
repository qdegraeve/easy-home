require "rails_helper"

RSpec.describe "Equipment suggestions", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household) }
  let(:user) { create(:household_member, household:, role: :member).user }

  around { |example| travel_to(Time.zone.parse("2026-11-23 10:00")) { example.run } }

  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }
  end

  it "offers the upkeep of a new dishwasher, unchecked with its first dates, and adds the checked ones" do
    sign_in(user)
    post equipment_index_path, params: { equipment: { kind: "dishwasher" } }
    equipment = household.equipment.sole
    follow_redirect!

    text = response.parsed_body.text.squish
    expect(text).to include(
      "Ajouter des tâches d'entretien ?",
      "Nettoyer le filtre Tous les mois · 1re fois le mer 23 déc.",
      "Remettre du sel Quand il le faut"
    )
    expect(response.parsed_body.css("input[type=checkbox][checked]")).to be_empty

    post equipment_suggestions_path(equipment), params: { keys: %w[dishwasher.filter dishwasher.salt] }
    expect(response).to redirect_to(equipment_path(equipment))
    expect(flash[:notice]).to eq("2 tâches d'entretien ajoutées.")
    expect(equipment.tasks.pluck(:title)).to contain_exactly("Nettoyer le filtre", "Remettre du sel")

    get root_path
    expect(response.parsed_body.text.squish) # nothing due the day it is added
      .to include("Tout est à jour", "Prochaine tâche : Nettoyer le filtre, dans 30 j")
  end

  it "says when nothing is checked, goes straight to an equipment of its own, and skips the screen once all added" do
    sign_in(user)
    post equipment_index_path, params: { equipment: { kind: "other", name: "Portail" } }
    expect(response).to redirect_to(equipment_path(household.equipment.sole))

    heater = create(:equipment, household:, kind: "water_heater")
    post equipment_suggestions_path(heater), params: { keys: [] }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.text).to include("Aucune tâche cochée.")

    Tasks::AddSuggestions.new.call(subject: heater, keys: %w[water_heater.safety_valve water_heater.anode])
    get new_equipment_suggestions_path(heater)
    expect(response).to redirect_to(equipment_path(heater))
  end

  it "offers the suggestions of its kind in the task form of an equipment, prefilled on a tap, none for a plant" do
    pool = create(:equipment, household:, kind: "pool")
    plant = create(:plant, :watered, household:)
    sign_in(user)

    get new_equipment_task_path(pool)
    expect(response.parsed_body.text).to include("Mesurer le pH et le chlore")
    get new_equipment_task_path(pool, suggestion: "pool.ph")
    expect(response.body).to include('value="Mesurer le pH et le chlore"', 'value="pool.ph"')
    get new_equipment_task_path(pool, suggestion: "bins.yellow")
    expect(response.body).not_to include('value="bins.yellow"')

    get new_plant_task_path(plant, suggestion: "pool.ph")
    expect(response.body).not_to include("Mesurer le pH")
  end

  it "answers 404 to a guest or another household" do
    pool = create(:equipment, household:, kind: "pool")

    [ create(:household_member, household:, role: :guest).user, create(:user, :with_household) ].each do |intruder|
      sign_in(intruder)
      get new_equipment_suggestions_path(pool)
      expect(response).to have_http_status(:not_found)
      post equipment_suggestions_path(pool), params: { keys: %w[pool.ph] }
      expect(response).to have_http_status(:not_found)
    end
    expect(pool.tasks).to be_empty
  end
end
