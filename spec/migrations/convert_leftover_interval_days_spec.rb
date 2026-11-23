require "rails_helper"
require Rails.root.join("db/migrate/20261124100100_convert_leftover_interval_days")

# Data transformation (docs/tests.md): a sliding task left in the former format is read again once converted.
RSpec.describe ConvertLeftoverIntervalDays do
  let(:migration) { described_class.new.tap { _1.verbose = false } }

  it "converts a task left in days, keeps its start date, and leaves the converted ones as they are" do
    left = create(:task)
    left.update_columns(recurrence_config: { "interval_days" => 5, "start_on" => "2026-12-01" })
    monthly = create(:task)
    monthly.update_columns(recurrence_config: { "interval" => 2, "unit" => "months" })

    migration.up

    expect(left.reload.recurrence).to have_attributes(interval: 5, unit: "days", start_on: Date.new(2026, 12, 1))
    expect(monthly.reload.recurrence_config).to eq("interval" => 2, "unit" => "months")
  end
end
