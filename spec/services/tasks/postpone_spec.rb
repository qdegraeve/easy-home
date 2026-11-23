require "rails_helper"

RSpec.describe Tasks::Postpone do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:plant) { create(:plant, :watered, interval_days: 7, last_watered_at: Time.zone.parse("2026-11-08 08:00")) }
  let(:occurrence) { plant.watering_task.pending_occurrence } # due on the 15th: late

  around { |example| travel_to(Time.zone.parse("2026-11-16 18:30")) { example.run } }

  it "closes a late occurrence as postponed, by the user, and opens the same task tomorrow" do
    postponed, tomorrow = described_class.new.call(occurrence:, user:).value!

    expect(postponed).to eq(occurrence)
    expect(occurrence.reload).to have_attributes(status: "postponed", completed_by: user, completed_at: Time.current)
    expect(tomorrow).to have_attributes(due_at: Time.zone.parse("2026-11-17 00:00"), status: "pending")
    expect(plant.watering_task.occurrences.pending.sole).to eq(tomorrow)
  end

  it "leaves the recurrence alone: done tomorrow, the next one starts from that day" do
    _, tomorrow = described_class.new.call(occurrence:, user:).value!
    travel 1.day

    Tasks::Complete.new.call(occurrence: tomorrow, user:)
    expect(plant.watering_task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-24 00:00"))
  end

  it "postpones only an open occurrence of an active task, due today or late" do
    later = create(:task_occurrence, task: create(:task), due_at: Time.zone.parse("2026-11-18 00:00"))
    expect(described_class.new.call(occurrence: later, user:).failure.first).to eq(:not_due)

    described_class.new.call(occurrence:, user:)
    # A double tap: the task, now due tomorrow, is not due yet.
    expect(described_class.new.call(occurrence:, user:).failure.first).to eq(:not_due)

    stopped = create(:task, active: false)
    expect(described_class.new.call(occurrence: create(:task_occurrence, task: stopped), user:).failure.first)
      .to eq(:inactive)
  end

  it "makes a stale tap on \"Fait\" do the task, now due tomorrow" do
    stale_copy = TaskOccurrence.find(occurrence.id)
    _, tomorrow = described_class.new.call(occurrence:, user:).value!

    expect(Tasks::Complete.new.call(occurrence: stale_copy, user:).value!).to eq(tomorrow)
    expect(tomorrow.reload).to be_done
  end

  it "postpones the task still open when tapped on a page shown before the miss" do
    stale_copy = TaskOccurrence.find(occurrence.id)
    today = Date.new(2026, 11, 18)
    Tasks::MarkMissed.new.call(today:) # due on the 15th, 2 days of tolerance
    reopened = plant.watering_task.occurrences.pending.sole

    postponed, tomorrow = described_class.new.call(occurrence: stale_copy, user:, today:).value!
    expect(postponed).to eq(reopened)
    # A new due date, missed again once if left (docs/domaine.md).
    expect(tomorrow).to have_attributes(due_at: Time.zone.parse("2026-11-19 00:00"), reopened_after_miss: false)
  end

  it "is undone from the toast, until tomorrow's task is done" do
    _, tomorrow = described_class.new.call(occurrence:, user:).value!

    expect(Tasks::CancelPostponement.new.call(occurrence:)).to be_success
    expect(occurrence.reload).to have_attributes(status: "pending", completed_at: nil, completed_by: nil)
    expect(TaskOccurrence.exists?(tomorrow.id)).to be(false)
    expect(Tasks::CancelPostponement.new.call(occurrence:).failure.first).to eq(:not_postponed)

    _, tomorrow = described_class.new.call(occurrence:, user:).value!
    Tasks::Complete.new.call(occurrence: tomorrow, user:)
    expect(Tasks::CancelPostponement.new.call(occurrence:).failure.first).to eq(:too_late)
  end

  it "keeps the postponement when a later completion is cancelled: due the day after it, not before" do
    _, tomorrow = described_class.new.call(occurrence:, user:).value!
    travel 1.day
    done = Tasks::Complete.new.call(occurrence: tomorrow, user:).value!

    Tasks::CancelCompletion.new.call(occurrence: done)
    expect(plant.watering_task.occurrences.pending.sole.due_at).to eq(Time.zone.parse("2026-11-17 00:00"))
  end
end
