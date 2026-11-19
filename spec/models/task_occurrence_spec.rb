require "rails_helper"

RSpec.describe TaskOccurrence, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  it "requires the completion time of a done occurrence" do
    expect(build(:task_occurrence, status: :done, completed_at: nil)).not_to be_valid
    expect(build(:task_occurrence, status: :pending, completed_at: nil)).to be_valid
  end

  describe ".done_on?" do
    it "counts the local day (Indian/Reunion), not the UTC day" do
      task = create(:task)
      # 2026-11-17 01:00 in Reunion = 2026-11-16 21:00 UTC
      create(:task_occurrence, :done, task:, completed_at: Time.zone.parse("2026-11-17 01:00"))

      expect(task.occurrences.done_on?(Date.new(2026, 11, 17))).to be(true)
      expect(task.occurrences.done_on?(Date.new(2026, 11, 16))).to be(false)
    end
  end
end
