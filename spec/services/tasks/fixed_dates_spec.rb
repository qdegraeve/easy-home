require "rails_helper"

# Fixed dates through the task services (docs/conception/equipements-et-taches.md, "Après un oubli"): the yellow bin
# every other Tuesday from Tuesday December 1st 2026 (must not be missed), and a yearly flexible task.
RSpec.describe "Fixed dates", type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household) }
  let(:user) { create(:household_member, household:).user }

  def add(title:, due_on:, interval:, unit:, critical: false)
    params = { title:, recurrence_type: "fixed", due_on:, interval:, unit:, critical: critical ? "1" : "0" }
    Tasks::Add.new.call(household:, params:).value!
  end

  def bins
    add(title: "Sortir la poubelle jaune", due_on: "2026-12-01", interval: "2", unit: "weeks", critical: true)
  end

  def due_on(task)
    task.reload.pending_occurrence&.due_at&.to_date
  end

  # Time moves forward through the example (travel_to without a block: the around block already travels).
  def at(time)
    travel_to(Time.zone.parse(time))
    yield
  end

  def complete(task, at:)
    at(at) { Tasks::Complete.new.call(occurrence: task.reload.pending_occurrence, user:) }
  end

  def mark_missed(at:)
    at(at) { Tasks::MarkMissed.new.call }
  end

  around { |example| travel_to(Time.zone.parse("2026-11-20 10:00")) { example.run } }

  it "opens the anchor, then two weeks later whether done the evening before, on the day or late" do
    [ "2026-11-30 19:00", "2026-12-01 07:00", "2026-12-02 09:00" ].each do |done_at|
      task = bins
      expect(due_on(task)).to eq(Date.new(2026, 12, 1))

      complete(task, at: done_at)

      expect(due_on(task)).to eq(Date.new(2026, 12, 15)), done_at
      task.destroy!
    end
  end

  it "comes back to the rule after a postponement done the next day" do
    task = bins
    at("2026-12-01 08:00") { Tasks::Postpone.new.call(occurrence: task.pending_occurrence, user:) }
    expect(due_on(task)).to eq(Date.new(2026, 12, 2))

    complete(task, at: "2026-12-02 08:00")

    expect(due_on(task)).to eq(Date.new(2026, 12, 15))
  end

  it "misses a forgotten collection the next day and opens the next one, never catching it up" do
    task = bins

    mark_missed(at: "2026-12-02 01:00")

    expect(task.occurrences.missed.sole.due_at.to_date).to eq(Date.new(2026, 12, 1))
    expect(due_on(task)).to eq(Date.new(2026, 12, 15))
    expect(task.pending_occurrence).not_to be_reopened_after_miss
  end

  it "reopens a forgotten flexible yearly task once, then back on its day the next year" do
    task = add(title: "Préparer la saison cyclonique", due_on: "2026-11-01", interval: "1", unit: "years")
    expect(due_on(task)).to eq(Date.new(2027, 11, 1)) # a past anchor jumps to its next date

    task = add(title: "Vérifier la trousse", due_on: "2026-11-25", interval: "1", unit: "years")
    mark_missed(at: "2026-11-29 01:00") # 3 days of tolerance
    expect(task.occurrences.missed.count).to eq(1)
    expect(task.reload.pending_occurrence).to have_attributes(reopened_after_miss: true)
    expect(due_on(task)).to eq(Date.new(2026, 11, 25))

    mark_missed(at: "2026-12-10 01:00")
    expect(task.occurrences.missed.count).to eq(1) # never missed again

    complete(task, at: "2026-12-10 09:00")
    expect(due_on(task)).to eq(Date.new(2027, 11, 25))
  end

  it "comes back to the open date when a completion is cancelled" do
    task = bins
    done = complete(task, at: "2026-12-01 07:00").value!

    at("2026-12-01 08:00") { Tasks::CancelCompletion.new.call(occurrence: done) }

    expect(due_on(task)).to eq(Date.new(2026, 12, 1))
    expect(task.occurrences.done).to be_empty
  end

  it "replays the rule after a cancelled completion that followed a miss" do
    task = bins
    mark_missed(at: "2026-12-02 01:00")
    done = complete(task, at: "2026-12-15 07:00").value!
    expect(due_on(task)).to eq(Date.new(2026, 12, 29))

    at("2026-12-15 08:00") { Tasks::CancelCompletion.new.call(occurrence: done) }

    expect(due_on(task)).to eq(Date.new(2026, 12, 15))
  end

  it "moves the whole series when the next date is edited" do
    task = bins

    Tasks::Update.new.call(task:, params: { title: task.title, recurrence_type: "fixed", due_on: "2026-12-03",
                                            interval: "2", unit: "weeks" })
    complete(task, at: "2026-12-03 07:00")

    expect(due_on(task)).to eq(Date.new(2026, 12, 17))
  end
end
