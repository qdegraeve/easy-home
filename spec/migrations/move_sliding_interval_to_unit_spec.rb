require "rails_helper"
require Rails.root.join("db/migrate/20261123130000_move_sliding_interval_to_unit")

# Data transformation (docs/tests.md): the existing sliding tasks keep their rule, in days, and their start date.
RSpec.describe MoveSlidingIntervalToUnit do
  def config_of(task)
    Task.connection.select_value("SELECT recurrence_config FROM tasks WHERE id = #{task.id}").then { JSON.parse(_1) }
  end

  def write(task, config)
    task.update_columns(recurrence_config: config)
  end

  it "moves interval_days to interval and unit, keeping the start date, and back" do
    watering = create(:task, subject: nil)
    pruning = create(:task, subject: nil, template_key: nil)
    one_off = create(:task, subject: nil, template_key: nil, recurrence_type: :once,
                            recurrence_config: { "due_on" => "2026-11-20" })
    bins = create(:task, subject: nil, template_key: nil, recurrence_type: :fixed,
                         recurrence_config: { "anchor_on" => "2026-12-01", "interval" => 2, "unit" => "weeks" })
    write(watering, { "interval_days" => 3 })
    write(pruning, { "interval_days" => 14, "start_on" => "2026-11-20" })

    migration = described_class.new
    migration.verbose = false
    migration.up
    migration.up # a second run changes nothing

    expect(config_of(watering)).to eq("interval" => 3, "unit" => "days")
    expect(config_of(pruning)).to eq("interval" => 14, "unit" => "days", "start_on" => "2026-11-20")
    expect(config_of(one_off)).to eq("due_on" => "2026-11-20")
    expect(config_of(bins)).to eq("anchor_on" => "2026-12-01", "interval" => 2, "unit" => "weeks")
    expect(pruning.reload.recurrence).to have_attributes(interval_days: 14, start_on: Date.new(2026, 11, 20))

    migration.down # fixed dates in weeks do not stop it
    expect(config_of(pruning)).to eq("interval_days" => 14, "start_on" => "2026-11-20")
    expect(config_of(bins)).to eq("anchor_on" => "2026-12-01", "interval" => 2, "unit" => "weeks")
  end

  it "refuses to go back once a rule counts in months" do
    task = create(:task, subject: nil, template_key: nil)
    write(task, { "interval" => 1, "unit" => "months" })

    migration = described_class.new
    migration.verbose = false
    expect { migration.down }.to raise_error(ActiveRecord::IrreversibleMigration)
  end
end
