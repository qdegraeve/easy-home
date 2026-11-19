require "rails_helper"

RSpec.describe Tasks::Complete do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:plant) { create(:plant, :watered, interval_days: 3, last_watered_at: Time.zone.parse("2026-11-10 08:00")) }
  let(:occurrence) { plant.watering_task.pending_occurrence }

  around { |example| travel_to(Time.zone.parse("2026-11-16 18:30")) { example.run } }

  it "marque l'échéance faite et crée la suivante depuis la réalisation (glissante, même en retard)" do
    result = described_class.new.call(occurrence:, user:)

    expect(result).to be_success
    expect(occurrence.reload).to have_attributes(
      status: "done",
      completed_by: user,
      completed_at: Time.zone.parse("2026-11-16 18:30")
    )
    expect(plant.reload.watering_task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-19 00:00"))
  end

  it "n'arrose pas deux fois sur un double appui" do
    stale_copy = TaskOccurrence.find(occurrence.id)
    described_class.new.call(occurrence:, user:)

    result = described_class.new.call(occurrence: stale_copy, user:)

    expect(result.failure.first).to eq(:not_pending)
    expect(plant.watering_task.occurrences.done.count).to eq(2)
    expect(plant.watering_task.occurrences.pending.count).to eq(1)
  end

  it "refuse un second arrosage le même jour, l'accepte le lendemain" do
    described_class.new.call(occurrence:, user:)
    next_occurrence = plant.reload.watering_task.pending_occurrence

    expect(described_class.new.call(occurrence: next_occurrence, user:).failure.first).to eq(:already_done_today)
    expect(next_occurrence.reload).to be_pending

    travel 1.day
    expect(described_class.new.call(occurrence: next_occurrence, user:)).to be_success
  end

  it "ne crée aucune échéance suivante pour une tâche unique" do
    task = Tasks::Add.new.call(subject: plant, params: { title: "Tailler", due_on: "2026-11-16" }).value!

    expect(described_class.new.call(occurrence: task.pending_occurrence, user:)).to be_success
    expect(task.reload.pending_occurrence).to be_nil
    expect(task.occurrences.done.count).to eq(1)
  end

  it "refuse une tâche désactivée sans rien écrire" do
    plant.watering_task.update!(active: false)

    result = described_class.new.call(occurrence:, user:)

    expect(result.failure.first).to eq(:inactive)
    expect(occurrence.reload).to be_pending
  end
end
