require "rails_helper"

RSpec.describe Tasks::RecordDone do
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household) }
  let(:user) { create(:household_member, household:).user }
  let(:equipment) { create(:equipment, household:, name: "Lave-vaisselle") }
  let(:salt) do
    Tasks::Add.new.call(subject: equipment, params: { title: "Remettre du sel", recurrence_type: "on_demand" }).value!
  end

  around { |example| travel_to(Time.zone.parse("2026-11-16 10:00")) { example.run } }

  it "has no open occurrence, and records a completion in the journal, due the day it is done" do
    expect(salt.occurrences).to be_empty

    done = described_class.new.call(task: salt, user:).value!

    expect(done).to have_attributes(status: "done", completed_by: user, due_at: Time.zone.parse("2026-11-16 00:00"))
    expect(salt.occurrences.pending).to be_empty
  end

  it "records it once a day, on an active task done when needed only" do
    described_class.new.call(task: salt, user:)
    expect(described_class.new.call(task: salt, user:).failure.first).to eq(:already_done_today)

    salt.update!(active: false)
    travel 1.day
    expect(described_class.new.call(task: salt, user:).failure.first).to eq(:inactive)

    dated = Tasks::Add.new.call(subject: equipment, params: { title: "Filtre", due_on: "2026-11-20" }).value!
    expect(described_class.new.call(task: dated, user:).failure.first).to eq(:not_on_demand)
  end

  it "is undone from the journal without opening any due date" do
    done = described_class.new.call(task: salt, user:).value!

    Tasks::CancelCompletion.new.call(occurrence: done)

    expect(salt.occurrences).to be_empty
  end

  it "turns into a monthly task with a due date, and back to when needed without one" do
    Tasks::Update.new.call(task: salt, params: { title: "Remettre du sel", recurrence_type: "sliding",
                                                 due_on: "2026-12-01", interval: "1", unit: "months" })
    expect(salt.reload.pending_occurrence.due_at.to_date).to eq(Date.new(2026, 12, 1))

    Tasks::Update.new.call(task: salt, params: { title: "Remettre du sel", recurrence_type: "on_demand" })
    expect(salt.reload.occurrences.pending).to be_empty
    expect(salt).to be_on_demand
  end
end
