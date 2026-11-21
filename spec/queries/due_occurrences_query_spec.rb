require "rails_helper"

RSpec.describe DueOccurrencesQuery do
  include ActiveSupport::Testing::TimeHelpers

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  let(:household) { create(:household) }
  let(:today) { Date.new(2026, 11, 16) }

  def occurrence_due(on, household: self.household, active: true)
    task = create(
      :task,
      household:,
      subject: nil,
      title: "Tâche du #{on}",
      template_key: nil,
      recurrence_type: :once,
      recurrence_config: { "due_on" => on.iso8601 },
      active:
    )
    task.occurrences.create!(due_at: on.in_time_zone)
  end

  it "keeps the open occurrences due today or late, of the active tasks of the households" do
    late, due_today = occurrence_due(today - 2), occurrence_due(today)
    occurrence_due(today + 1)
    occurrence_due(today, active: false)
    occurrence_due(today, household: create(:household))
    occurrence_due(today - 1).update!(status: :done, completed_at: Time.current)

    expect(described_class.new.call(household_ids: household.id, today:)).to contain_exactly(late, due_today)
  end

  it "also keeps the next days with days_ahead, up to the last one included" do
    due_today, in_three_days = occurrence_due(today), occurrence_due(today + 3)
    occurrence_due(today + 4)

    result = described_class.new.call(household_ids: household.id, today:, days_ahead: 3)

    expect(result).to contain_exactly(due_today, in_three_days)
  end
end
