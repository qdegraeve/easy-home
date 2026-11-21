require "rails_helper"

RSpec.describe Tasks::CancelMany do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }

  around { |example| travel_to(Time.zone.parse("2026-11-16 18:30")) { example.run } }

  def done_watering(name)
    plant = create(:plant, :watered, name:, interval_days: 3, last_watered_at: Time.zone.parse("2026-11-12 08:00"))
    Tasks::Complete.new.call(occurrence: plant.watering_task.pending_occurrence, user:).value!
  end

  it "cancels each completion and reschedules from the previous one" do
    lemon, basil = done_watering("Citronnier"), done_watering("Basilic")

    result = described_class.new.call(occurrences: [ lemon, basil ])

    expect(result.value!).to contain_exactly(lemon, basil)
    expect(TaskOccurrence.where(id: [ lemon.id, basil.id ])).to be_empty
    expect(lemon.task.reload.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-15 00:00"))
  end

  it "fails when nothing was done" do
    plant = create(:plant, :watered, interval_days: 3)

    result = described_class.new.call(occurrences: [ plant.watering_task.pending_occurrence ])

    expect(result.failure).to eq([ :nothing_cancelled ])
  end
end
