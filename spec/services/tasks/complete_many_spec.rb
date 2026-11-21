require "rails_helper"

RSpec.describe Tasks::CompleteMany do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }

  around { |example| travel_to(Time.zone.parse("2026-11-16 18:30")) { example.run } }

  def due_watering(name)
    plant = create(:plant, :watered, name:, interval_days: 3, last_watered_at: Time.zone.parse("2026-11-12 08:00"))
    plant.watering_task.pending_occurrence
  end

  it "does each occurrence and schedules its next one" do
    lemon, basil = due_watering("Citronnier"), due_watering("Basilic")

    result = described_class.new.call(occurrences: [ lemon, basil ], user:)

    expect(result.value!).to contain_exactly(lemon, basil)
    expect([ lemon.reload, basil.reload ].map(&:status)).to eq(%w[done done])
    expect(lemon.task.reload.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-19 00:00"))
  end

  it "skips an occurrence already done, without preventing the others" do
    lemon, basil = due_watering("Citronnier"), due_watering("Basilic")
    stale_lemon = TaskOccurrence.find(lemon.id)
    Tasks::Complete.new.call(occurrence: lemon, user:)

    result = described_class.new.call(occurrences: [ stale_lemon, basil ], user:)

    expect(result.value!).to eq([ basil ])
  end

  it "fails when nothing could be done" do
    lemon = due_watering("Citronnier")
    Tasks::Complete.new.call(occurrence: lemon, user:)

    result = described_class.new.call(occurrences: [ TaskOccurrence.find(lemon.id) ], user:)

    expect(result.failure).to eq([ :nothing_done ])
  end
end
