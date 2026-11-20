require "rails_helper"

RSpec.describe Plants::AcceptAction do
  include ActiveSupport::Testing::TimeHelpers

  let(:plant) { create(:plant, :watered) }
  let(:analysis) do
    create(:plant_analysis, :with_proposals, plant:, finished_at: Time.zone.parse("2026-11-16 09:00"))
  end

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  it "adds a one-off task due the proposed number of days after the analysis" do
    result = described_class.new.call(analysis:, index: 0)

    task = result.value!
    expect(task).to have_attributes(title: "Pailler le pied", recurrence_type: "once", subject: plant)
    expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-19 00:00"))
    expect(analysis.reload).to be_action_accepted(0)
  end

  it "makes the task due today when the proposed date is already past" do
    travel_to(Time.zone.parse("2026-11-25 10:00"))

    task = described_class.new.call(analysis:, index: 0).value!

    expect(task.pending_occurrence.due_at).to eq(Time.zone.parse("2026-11-25 00:00"))
  end

  it "adds each action once only" do
    described_class.new.call(analysis:, index: 0)

    result = described_class.new.call(analysis:, index: 0)

    expect(result.failure.first).to eq(:already_accepted)
    expect(plant.tasks.where(title: "Pailler le pied").count).to eq(1)
  end

  it "refuses an action that does not exist" do
    [ 1, -1 ].each do |index|
      expect(described_class.new.call(analysis:, index:).failure.first).to eq(:not_acceptable)
    end
    expect(plant.tasks.count).to eq(1)
  end

  it "adds nothing to an archived plant" do
    plant.update!(archived_at: Time.current)

    result = described_class.new.call(analysis:, index: 0)

    expect(result.failure.first).to eq(:subject_archived)
    expect(analysis.reload.applied_action_indexes).to be_empty
    expect(plant.tasks.count).to eq(1)
  end
end
