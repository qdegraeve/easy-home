require "rails_helper"

RSpec.describe Plants::Add do
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household) }
  let(:user) { create(:household_member, household:).user }
  let(:location) { create(:location, household:) }
  let(:params) do
    { name: "Hibiscus", species: "Hibiscus rosa-sinensis", location_id: location.id.to_s,
      watering_interval_days: "3", last_watered_on: "2026-11-14" }
  end

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  it "crée la plante, sa tâche d'arrosage, le dernier arrosage au journal et la prochaine échéance" do
    result = described_class.new.call(household:, user:, params:)

    plant = result.value!
    expect(plant).to have_attributes(name: "Hibiscus", species: "Hibiscus rosa-sinensis", location:)
    expect(plant).to be_species_from_user
    task = plant.watering_task
    expect(task).to have_attributes(household:, recurrence_type: "sliding", recurrence_config: { "interval_days" => 3 })
    expect(task.occurrences.done.sole).to have_attributes(
      completed_at: Time.zone.parse("2026-11-14"),
      completed_by: user
    )
    expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-17 00:00"))
  end

  it "part d'aujourd'hui sans dernier arrosage saisi, sans espèce ni emplacement" do
    plant = described_class.new.call(
      household:, user:, params: { name: "Basilic", watering_interval_days: "2" }
    ).value!

    expect(plant).to have_attributes(species: nil, species_source: nil, location: nil)
    expect(plant.watering_task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-18 00:00"))
  end

  {
    "sans nom" => { name: " " },
    "intervalle à 0" => { watering_interval_days: "0" },
    "intervalle au-delà de 60" => { watering_interval_days: "61" },
    "intervalle non numérique" => { watering_interval_days: "abc" },
    "dernier arrosage dans le futur" => { last_watered_on: "2026-11-17" },
    "dernier arrosage vide" => { last_watered_on: "" }
  }.each do |label, override|
    it "refuse une saisie #{label}, sans rien créer" do
      result = nil

      expect { result = described_class.new.call(household:, user:, params: params.merge(override)) }
        .not_to change(Plant, :count)
      expect(result).to be_failure
      expect(result.failure.first).to eq(:invalid)
    end
  end

  it "refuse l'emplacement d'un autre foyer" do
    result = described_class.new.call(household:, user:, params: params.merge(location_id: create(:location).id.to_s))

    expect(result.failure.last.errors[:location_id]).to be_present
    expect(Plant.count).to eq(0)
  end
end
