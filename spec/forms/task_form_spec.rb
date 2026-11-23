require "rails_helper"

RSpec.describe TaskForm do
  def form(recurrence_type, interval, unit)
    described_class.new(title: "Tâche", due_on: Date.new(2026, 12, 1), recurrence_type:, interval:, unit:)
  end

  it "accepts every N days, weeks, months or years after the last time within their bounds" do
    { "days" => 60, "weeks" => 52, "months" => 24, "years" => 10 }.each do |unit, max|
      expect(form("sliding", max, unit)).to be_valid, unit
      expect(form("sliding", max + 1, unit)).not_to be_valid, unit
      expect(form("sliding", 0, unit)).not_to be_valid, unit
    end
    expect(form("sliding", 3, "hours")).not_to be_valid
    expect(form("sliding", 3, nil)).not_to be_valid
  end

  it "accepts fixed dates in weeks or years only, with their own message" do
    expect(form("fixed", 2, "weeks")).to be_valid
    expect(form("fixed", 1, "years")).to be_valid

    months = form("fixed", 3, "months")
    expect(months).not_to be_valid
    expect(months.errors[:interval].join).to include("pour un jour fixe")
  end

  it "ignores the interval of a one-off task" do
    expect(form("once", nil, nil)).to be_valid
  end

  it "needs no date for a task done when needed, and keeps neither reminder nor importance for it" do
    form = described_class.new(title: "Sel", recurrence_type: "on_demand", reminder_time: "19:00", critical: true)

    expect(form).to be_valid
    expect(form.task_attributes).to include(recurrence_config: {}, reminder_minute: nil, importance: "flexible")
  end

  it "reads back each rhythm of a task" do
    household = create(:household)
    { "once" => {}, "sliding" => { interval: "3", unit: "months" }, "fixed" => { interval: "2", unit: "weeks" },
      "on_demand" => {} }.each do |rhythm, extra|
      params = { title: rhythm, recurrence_type: rhythm, due_on: ("2026-12-01" unless rhythm == "on_demand"), **extra }
      task = Tasks::Add.new.call(household:, params:).value!

      form = described_class.from(task)

      expect(form).to be_valid, rhythm
      expect(form.recurrence_type).to eq(rhythm)
    end
  end
end
