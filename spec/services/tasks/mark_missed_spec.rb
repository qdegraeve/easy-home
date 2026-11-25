require "rails_helper"

RSpec.describe Tasks::MarkMissed do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-22 01:05")) { example.run } }

  def task_due(on, interval_days: 7, importance: :flexible, recurrence_type: :sliding, active: true)
    config = recurrence_type == :once ? { "due_on" => on.iso8601 } : { "interval" => interval_days, "unit" => "days" }
    task = create(:task, importance:, recurrence_type:, recurrence_config: config, active:, template_key: nil)
    create(:task_occurrence, task:, due_at: on.in_time_zone)
    task
  end

  def run
    described_class.new.call.value!
  end

  it "misses a flexible task only past its tolerance (7 days: 2 days), then reopens it with the same due date" do
    still_in_margin = task_due(Date.new(2026, 11, 20)) # due + 2 = today
    past_margin = task_due(Date.new(2026, 11, 19))

    expect(run).to eq(1)

    expect(still_in_margin.occurrences.sole).to be_pending
    missed = past_margin.occurrences.missed.sole
    expect(missed).to have_attributes(completed_at: Time.current, completed_by: nil)
    expect(past_margin.occurrences.pending.sole)
      .to have_attributes(due_at: Time.zone.parse("2026-11-19 00:00"), reopened_after_miss: true)
  end

  it "misses a due date once: the reopened occurrence stays to do, however late, until done" do
    task = task_due(Date.new(2026, 11, 1), interval_days: 1) # no tolerance

    run
    travel 20.days
    expect(run).to eq(0)
    expect(task.occurrences.group(:status).count).to eq("missed" => 1, "pending" => 1)

    Tasks::Complete.new.call(occurrence: task.occurrences.pending.sole, user: create(:user))
    travel 2.days
    expect(run).to eq(1) # the next due date, a new one
  end

  it "misses a task that must not be missed the day after, and a one-off one is then over" do
    repeating = task_due(Date.new(2026, 11, 21), importance: :critical)
    one_off = task_due(Date.new(2026, 11, 21), importance: :critical, recurrence_type: :once)
    today = task_due(Date.new(2026, 11, 22), importance: :critical)

    expect(run).to eq(2)

    expect(repeating.occurrences.pending.sole.due_at).to eq(Time.zone.parse("2026-11-21 00:00"))
    expect(one_off.occurrences.map(&:status)).to eq([ "missed" ])
    expect(today.occurrences.sole).to be_pending
  end

  it "never misses a flexible one-off task, nor a stopped task" do
    one_off = task_due(Date.new(2026, 10, 1), recurrence_type: :once)
    stopped = task_due(Date.new(2026, 10, 1), active: false)

    expect(run).to eq(0)
    expect([ one_off, stopped ].map { |task| task.occurrences.sole.status }).to eq(%w[pending pending])
  end

  it "misses an occurrence once, however often it runs" do
    task = task_due(Date.new(2026, 11, 1))

    run
    expect(run).to eq(0)
    expect(task.occurrences.group(:status).count).to eq("missed" => 1, "pending" => 1)
  end

  it "lets a completion of the same moment win: done while waiting for the task lock, it is not missed" do
    task = task_due(Date.new(2026, 11, 1))
    occurrence = task.occurrences.sole
    completed = false
    allow_any_instance_of(Task).to receive(:lock!).and_wrap_original do |original, *args|
      unless completed
        completed = true
        Tasks::Complete.new.call(occurrence: TaskOccurrence.find(occurrence.id), user: create(:user))
      end
      original.call(*args)
    end

    expect(run).to eq(0)
    expect(occurrence.reload).to be_done
    expect(task.occurrences.missed).to be_empty
  end
end
