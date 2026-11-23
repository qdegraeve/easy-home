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

  it "refuses a stale tap after a miss moved the task to the next collection, doing nothing" do
    task = bins
    missed = task.pending_occurrence

    result = at("2026-12-02 00:30") do
      Tasks::MarkMissed.new.call
      Tasks::Complete.new.call(occurrence: missed, user:)
    end

    expect(result.failure.first).to eq(:missed)
    expect(due_on(task)).to eq(Date.new(2026, 12, 15))
    expect(task.occurrences.done).to be_empty
  end

  it "misses a postponed collection forgotten the next day, then opens the next one" do
    task = bins
    at("2026-12-01 08:00") { Tasks::Postpone.new.call(occurrence: task.pending_occurrence, user:) }

    mark_missed(at: "2026-12-03 01:00")

    expect(task.occurrences.missed.sole.due_at.to_date).to eq(Date.new(2026, 12, 2))
    expect(due_on(task)).to eq(Date.new(2026, 12, 15))
  end

  it "brings back the postponed date when its completion is cancelled" do
    task = bins
    at("2026-12-01 08:00") { Tasks::Postpone.new.call(occurrence: task.pending_occurrence, user:) }
    done = complete(task, at: "2026-12-02 07:00").value!

    at("2026-12-02 08:00") { Tasks::CancelCompletion.new.call(occurrence: done) }

    expect(due_on(task)).to eq(Date.new(2026, 12, 2))
  end

  it "reopens again a flexible task whose late completion after a miss is cancelled" do
    task = add(title: "Vérifier la trousse", due_on: "2026-11-25", interval: "1", unit: "years")
    mark_missed(at: "2026-11-29 01:00")
    done = complete(task, at: "2026-12-10 09:00").value!

    at("2026-12-10 10:00") { Tasks::CancelCompletion.new.call(occurrence: done) }

    expect(task.reload.pending_occurrence).to have_attributes(reopened_after_miss: true)
    expect(due_on(task)).to eq(Date.new(2026, 11, 25))
  end

  it "brings back a date past its tolerance when a late completion is cancelled: it is then missed like any other" do
    task = add(title: "Rentrer la poubelle", due_on: "2026-12-01", interval: "2", unit: "weeks")
    done = complete(task, at: "2026-12-03 09:00").value!

    at("2026-12-05 09:00") { Tasks::CancelCompletion.new.call(occurrence: done) }
    expect(due_on(task)).to eq(Date.new(2026, 12, 1))

    mark_missed(at: "2026-12-05 10:00")
    expect(task.occurrences.missed.sole.due_at.to_date).to eq(Date.new(2026, 12, 1))
    expect(task.reload.pending_occurrence).to have_attributes(reopened_after_miss: true)
  end

  describe "editing without changing the date" do
    def rename(task, title)
      form = TaskForm.from(task.reload)
      Tasks::Update.new.call(task:, params: form.attributes.merge("title" => title))
    end

    it "keeps the weekday of a postponed collection" do
      task = bins
      at("2026-12-01 08:00") { Tasks::Postpone.new.call(occurrence: task.pending_occurrence, user:) }

      rename(task, "Sortir le bac jaune")
      complete(task, at: "2026-12-02 07:00")

      expect(task.reload.recurrence.anchor_on).to eq(Date.new(2026, 12, 1))
      expect(due_on(task)).to eq(Date.new(2026, 12, 15))
    end

    it "keeps a flexible task reopened after a miss on its date" do
      task = add(title: "Vérifier la trousse", due_on: "2026-11-25", interval: "1", unit: "years")
      mark_missed(at: "2026-11-29 01:00")

      rename(task, "Vérifier la trousse de secours")

      expect(due_on(task)).to eq(Date.new(2026, 11, 25))
      expect(task.pending_occurrence).to be_reopened_after_miss
    end
  end
end
