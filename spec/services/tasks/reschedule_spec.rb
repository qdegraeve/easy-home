require "rails_helper"

RSpec.describe Tasks::Reschedule do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 18:30")) { example.run } }

  it "creates no occurrence for a stopped task" do
    task = create(:task, active: false)

    expect(described_class.new.call(task:).value!).to be_nil
    expect(task.occurrences).to be_empty
  end

  it "removes the open occurrence of a one-off task already done" do
    task = create(:task, recurrence_type: :once, recurrence_config: { "due_on" => "2026-11-20" })
    create(:task_occurrence, :done, task:)
    create(:task_occurrence, task:)

    expect(described_class.new.call(task:).value!).to be_nil
    expect(task.occurrences.pending).to be_empty
  end

  it "starts from the start date of a repeating task never done" do
    task = create(:task, recurrence_config: { "interval_days" => 14, "start_on" => "2026-11-25" })

    expect(described_class.new.call(task:).value!.due_at).to eq(Time.zone.parse("2026-11-25 00:00"))
  end

  it "starts from now when the task was never done" do
    task = create(:task, interval_days: 2)

    expect(described_class.new.call(task:).value!.due_at).to eq(Time.zone.parse("2026-11-18 00:00"))
  end
end
