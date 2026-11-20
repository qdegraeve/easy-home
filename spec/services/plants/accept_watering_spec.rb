require "rails_helper"

RSpec.describe Plants::AcceptWatering do
  include ActiveSupport::Testing::TimeHelpers

  let(:plant) { create(:plant, :watered, interval_days: 7, last_watered_at: Time.zone.parse("2026-11-15 08:00")) }
  let(:analysis) { create(:plant_analysis, :with_proposals, plant:) }

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  it "sets the proposed interval and reschedules the next watering from the last one" do
    expect(analysis).not_to be_watering_accepted

    result = described_class.new.call(analysis:)

    expect(result).to be_success
    task = plant.watering_task.reload
    expect(task.recurrence.interval_days).to eq(4)
    expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-19 00:00"))
    expect(task.occurrences.pending.count).to eq(1)
    expect(analysis).to be_watering_accepted
  end

  it "refuses an analysis without an interval" do
    analysis.update!(watering_interval_days: nil)

    expect(described_class.new.call(analysis:).failure.first).to eq(:not_acceptable)
    expect(plant.watering_task.reload.recurrence.interval_days).to eq(7)
  end

  it "refuses an archived plant" do
    plant.update!(archived_at: Time.current)

    expect(described_class.new.call(analysis:).failure.first).to eq(:subject_archived)
    expect(plant.watering_task.reload.recurrence.interval_days).to eq(7)
  end
end
