require "rails_helper"

RSpec.describe Plants::Update do
  include ActiveSupport::Testing::TimeHelpers

  let(:plant) do
    create(:plant, :watered, species: "Basilic", species_source: :ai, interval_days: 3,
                             last_watered_at: Time.zone.parse("2026-11-15 08:00"))
  end
  let(:params) { { name: plant.name, species: "Basilic", watering_interval_days: "3" } }

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  it "reschedules the open occurrence from the last watering when the interval changes" do
    described_class.new.call(plant:, params: params.merge(watering_interval_days: "5"))

    task = plant.watering_task.reload
    expect(task.recurrence.interval_days).to eq(5)
    expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-20 00:00"))
    expect(task.occurrences.count).to eq(2)
  end

  it "keeps the occurrence and the species source when nothing changes" do
    due_at = plant.watering_task.pending_occurrence.due_at

    described_class.new.call(plant:, params: params.merge(name: "Basilic de la terrasse"))

    expect(plant.reload).to have_attributes(name: "Basilic de la terrasse", species_source: "ai")
    expect(plant.watering_task.pending_occurrence.due_at).to eq(due_at)
  end

  it "marks the species as entered by the user when corrected, and clears it when emptied" do
    described_class.new.call(plant:, params: params.merge(species: "Ocimum basilicum"))
    expect(plant.reload).to have_attributes(species: "Ocimum basilicum", species_source: "user")

    described_class.new.call(plant:, params: params.merge(species: ""))
    expect(plant.reload).to have_attributes(species: nil, species_source: nil)
  end

  it "rejects an invalid interval without changing anything" do
    result = described_class.new.call(plant:, params: params.merge(watering_interval_days: "0"))

    expect(result.failure.first).to eq(:invalid)
    expect(plant.watering_task.reload.recurrence.interval_days).to eq(3)
  end
end
