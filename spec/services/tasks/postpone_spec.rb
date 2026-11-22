require "rails_helper"

RSpec.describe Tasks::Postpone do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:plant) { create(:plant, :watered, interval_days: 7, last_watered_at: Time.zone.parse("2026-11-08 08:00")) }
  let(:occurrence) { plant.watering_task.pending_occurrence } # due on the 15th: late

  around { |example| travel_to(Time.zone.parse("2026-11-16 18:30")) { example.run } }

  it "closes a late occurrence as postponed, by the user, and opens the same task tomorrow" do
    result = described_class.new.call(occurrence:, user:)

    expect(occurrence.reload).to have_attributes(status: "postponed", completed_by: user, completed_at: Time.current)
    expect(result.value!).to have_attributes(due_at: Time.zone.parse("2026-11-17 00:00"), status: "pending")
    expect(plant.watering_task.occurrences.pending.sole).to eq(result.value!)
  end

  it "leaves the recurrence alone: done tomorrow, the next one starts from that day" do
    tomorrow = described_class.new.call(occurrence:, user:).value!
    travel 1.day

    Tasks::Complete.new.call(occurrence: tomorrow, user:)
    expect(plant.watering_task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-24 00:00"))
  end

  it "postpones only an open occurrence of an active task, due today or late" do
    later = create(:task_occurrence, task: create(:task), due_at: Time.zone.parse("2026-11-18 00:00"))
    expect(described_class.new.call(occurrence: later, user:).failure.first).to eq(:not_due)

    described_class.new.call(occurrence:, user:)
    expect(described_class.new.call(occurrence:, user:).failure.first).to eq(:not_pending)

    stopped = create(:task, active: false)
    expect(described_class.new.call(occurrence: create(:task_occurrence, task: stopped), user:).failure.first)
      .to eq(:inactive)
  end

  it "makes a stale tap on \"Fait\" do the task, now due tomorrow" do
    stale_copy = TaskOccurrence.find(occurrence.id)
    tomorrow = described_class.new.call(occurrence:, user:).value!

    expect(Tasks::Complete.new.call(occurrence: stale_copy, user:).value!).to eq(tomorrow)
    expect(tomorrow.reload).to be_done
  end
end
