require "rails_helper"

RSpec.describe Tasks::Add do
  include ActiveSupport::Testing::TimeHelpers

  let!(:plant) { create(:plant, :watered) }

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  it "adds a one-off task, due on the chosen day, in the household of the plant" do
    task = described_class.new.call(
      subject: plant, params: { title: " Tailler ", recurrence_type: "once", due_on: "2026-11-30" }
    ).value!

    expect(task).to have_attributes(
      title: "Tailler", household: plant.household, subject: plant, template_key: nil,
      recurrence_type: "once", recurrence_config: { "due_on" => "2026-11-30" }
    )
    expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-30 00:00"))
  end

  it "adds a task of the house (no subject) to the given household, with its instructions trimmed" do
    household = create(:household)

    task = described_class.new.call(
      household:, params: { title: "Sortir la poubelle", due_on: "2026-11-17", instructions: "  Bac jaune.  " }
    ).value!

    expect(task).to have_attributes(household:, subject: nil, instructions: "Bac jaune.")
    expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-17 00:00"))
  end

  it "keeps no blank instructions, and refuses instructions too long" do
    household = create(:household)
    blank = described_class.new.call(household:, params: { title: "Aérer", due_on: "2026-11-17", instructions: " " })
    expect(blank.value!.instructions).to be_nil

    long = described_class.new.call(household:, params: { title: "Aérer", due_on: "2026-11-17",
                                                          instructions: "a" * (Task::INSTRUCTIONS_MAX + 1) })
    expect(long.failure.first).to eq(:invalid)
  end

  it "needs a subject or a household" do
    expect { described_class.new.call(params: { title: "Aérer", due_on: "2026-11-17" }) }.to raise_error(ArgumentError)
  end

  it "adds a task repeating every N days from the chosen date" do
    task = described_class.new.call(
      subject: plant,
      params: { title: "Engrais", recurrence_type: "sliding", due_on: "2026-11-20", interval_days: "14" }
    ).value!

    expect(task.recurrence).to have_attributes(interval_days: 14, start_on: Date.new(2026, 11, 20))
    expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-20 00:00"))
  end

  {
    "without a title" => { title: "" },
    "without a date" => { due_on: "" },
    "repeating without an interval" => { recurrence_type: "sliding", interval_days: "" },
    "repeating over 60 days" => { recurrence_type: "sliding", interval_days: "61" },
    "of an unknown type" => { recurrence_type: "weekly" }
  }.each do |label, override|
    it "rejects a task #{label}, without creating anything" do
      params = { title: "Tailler", recurrence_type: "once", due_on: "2026-11-30" }.merge(override)

      expect { expect(described_class.new.call(subject: plant, params:).failure.first).to eq(:invalid) }
        .not_to change(Task, :count)
    end
  end

  it "ignores the interval of a one-off task" do
    task = described_class.new.call(
      subject: plant, params: { title: "Tailler", recurrence_type: "once", due_on: "2026-11-30", interval_days: "abc" }
    ).value!

    expect(task.recurrence_config).to eq("due_on" => "2026-11-30")
  end

  it "rejects an archived plant" do
    plant.update!(archived_at: Time.current)

    result = described_class.new.call(subject: plant, params: { title: "Tailler", due_on: "2026-11-30" })

    expect(result.failure.first).to eq(:subject_archived)
    expect(plant.tasks.count).to eq(1)
  end
end
