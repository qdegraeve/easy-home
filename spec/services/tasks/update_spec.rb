require "rails_helper"

RSpec.describe Tasks::Update do
  include ActiveSupport::Testing::TimeHelpers

  let(:plant) { create(:plant, :watered) }

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  def add(params)
    Tasks::Add.new.call(subject: plant, params:).value!
  end

  it "changes the title and date of a one-off task" do
    task = add(title: "Tailler", recurrence_type: "once", due_on: "2026-11-30")

    described_class.new.call(task:, params: { title: "Tailler les fleurs fanées", due_on: "2026-12-05" })

    expect(task.reload).to have_attributes(
      title: "Tailler les fleurs fanées",
      recurrence_config: { "due_on" => "2026-12-05" }
    )
    expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-12-05 00:00"))
  end

  it "changes the interval and next date of a repeating task, keeping its rhythm when none is given" do
    task = add(title: "Engrais", recurrence_type: "sliding", due_on: "2026-11-20", interval: "14", unit: "days")

    described_class.new.call(task:, params: { title: "Engrais", due_on: "2026-11-25", interval: "21", unit: "days" })

    expect(task.reload).to be_sliding
    expect(task.recurrence.interval_days).to eq(21)
    expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-25 00:00"))
  end

  it "changes the rhythm of a task: a one-off becomes every N days, then fixed dates" do
    task = add(title: "Engrais", recurrence_type: "once", due_on: "2026-11-20")

    described_class.new.call(
      task:,
      params: { title: "Engrais", recurrence_type: "sliding", due_on: "2026-11-21", interval: "30", unit: "days" }
    )
    expect(task.reload.recurrence).to have_attributes(interval_days: 30, start_on: Date.new(2026, 11, 21))
    expect(task.pending_occurrence.due_at.to_date).to eq(Date.new(2026, 11, 21))

    described_class.new.call(
      task:, params: { title: "Engrais", recurrence_type: "fixed", due_on: "2026-12-01", interval: "4", unit: "weeks" }
    )
    expect(task.reload.recurrence).to have_attributes(anchor_on: Date.new(2026, 12, 1), interval: 4, unit: "weeks")
    expect(task.occurrences.pending.sole.due_at.to_date).to eq(Date.new(2026, 12, 1))
  end

  it "opens a due date when a one-off already done becomes a repeating task" do
    task = add(title: "Engrais", recurrence_type: "once", due_on: "2026-11-16")
    Tasks::Complete.new.call(occurrence: task.pending_occurrence, user: nil)

    described_class.new.call(
      task:,
      params: { title: "Engrais", recurrence_type: "sliding", due_on: "2026-12-16", interval: "30", unit: "days" }
    )

    expect(task.reload.pending_occurrence.due_at.to_date).to eq(Date.new(2026, 12, 16))
  end

  it "keeps the start date of a repeating task: cancelling all its completions goes back to it" do
    task = add(title: "Engrais", recurrence_type: "sliding", due_on: "2026-11-16", interval: "14", unit: "days")
    Tasks::Complete.new.call(occurrence: task.pending_occurrence, user: create(:user))

    described_class.new.call(
      task: task.reload,
      params: { title: "Engrais bio", due_on: "2026-11-30", interval: "14", unit: "days" }
    )
    Tasks::CancelCompletion.new.call(occurrence: task.occurrences.done.sole)

    expect(task.reload.recurrence.start_on).to eq(Date.new(2026, 11, 16))
    expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-16 00:00"))
  end

  it "makes the typed date the start date of a repeating task never done (kept after restore)" do
    task = add(title: "Engrais", recurrence_type: "sliding", due_on: "2026-11-20", interval: "14", unit: "days")

    described_class.new.call(task:, params: { title: "Engrais", due_on: "2026-11-25", interval: "14", unit: "days" })
    Plants::Archive.new.call(plant:)
    Plants::Restore.new.call(plant: plant.reload)

    expect(task.reload.recurrence.start_on).to eq(Date.new(2026, 11, 25))
    expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-25 00:00"))
  end

  it "rejects an update without a date instead of using today" do
    task = add(title: "Tailler", recurrence_type: "once", due_on: "2026-11-30")

    expect(described_class.new.call(task:, params: { title: "Tailler" }).failure.first).to eq(:invalid)
    expect(task.pending_occurrence.reload.due_at).to eq(Time.zone.parse("2026-11-30 00:00"))
  end

  it "rejects an invalid input without changing anything" do
    task = add(title: "Tailler", recurrence_type: "once", due_on: "2026-11-30")

    result = described_class.new.call(task:, params: { title: "", due_on: "2026-12-05" })

    expect(result.failure.first).to eq(:invalid)
    expect(task.reload.title).to eq("Tailler")
  end

  it "turns fixed dates into a one-off or every N days, and a sliding task already done into a one-off" do
    task = add(title: "Engrais", recurrence_type: "fixed", due_on: "2026-11-24", interval: "2", unit: "weeks")

    described_class.new.call(task:, params: { title: "Engrais", recurrence_type: "sliding", due_on: "2026-11-25",
                                              interval: "10", unit: "days" })
    expect(task.reload).to be_sliding
    expect(task.pending_occurrence.due_at.to_date).to eq(Date.new(2026, 11, 25))

    Tasks::Complete.new.call(occurrence: task.pending_occurrence, user: nil)
    described_class.new.call(task:, params: { title: "Engrais", recurrence_type: "once", due_on: "2026-11-30" })
    expect(task.reload.recurrence.due_on).to eq(Date.new(2026, 11, 30))
    expect(task.occurrences.pending.sole.due_at.to_date).to eq(Date.new(2026, 11, 30))

    described_class.new.call(task:, params: { title: "Engrais", recurrence_type: "fixed", due_on: "2026-12-01",
                                              interval: "1", unit: "weeks" })
    described_class.new.call(task:, params: { title: "Engrais", recurrence_type: "once", due_on: "2026-12-03" })
    expect(task.reload).to be_once
    expect(task.occurrences.pending.sole.due_at.to_date).to eq(Date.new(2026, 12, 3))
  end
end
