require "rails_helper"

RSpec.describe Tasks::CancelCompletion do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:plant) { create(:plant, :watered, interval_days: 3, last_watered_at: Time.zone.parse("2026-11-10 08:00")) }

  around { |example| travel_to(Time.zone.parse("2026-11-16 18:30")) { example.run } }

  it "removes the watering from the log and recomputes the occurrence from the previous watering" do
    Tasks::Complete.new.call(occurrence: plant.watering_task.pending_occurrence, user:)
    watering = plant.reload.watering_task.occurrences.done.order(:completed_at).last

    result = described_class.new.call(occurrence: watering)

    expect(result).to be_success
    task = plant.reload.watering_task
    expect(task.occurrences.done.count).to eq(1)
    # Due on the 13th after the previous watering, moved within its tolerance (1 day): not missed at once.
    expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-15 00:00"))
    expect(task.occurrences.pending.count).to eq(1)
  end

  it "starts over from now when the only watering is cancelled" do
    watering = plant.watering_task.occurrences.done.sole

    described_class.new.call(occurrence: watering)

    expect(plant.reload.watering_task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-19 00:00"))
  end

  it "puts a one-off task back to do, on its planned date" do
    task = Tasks::Add.new.call(subject: plant, params: { title: "Tailler", due_on: "2026-11-14" }).value!
    Tasks::Complete.new.call(occurrence: task.pending_occurrence, user:)

    described_class.new.call(occurrence: task.occurrences.done.sole)

    expect(task.reload.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-14 00:00"))
  end

  it "rejects an occurrence that is not done" do
    occurrence = plant.watering_task.pending_occurrence

    expect(described_class.new.call(occurrence:).failure.first).to eq(:not_done)
    expect(occurrence.reload).to be_pending
  end
end
