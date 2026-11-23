require "rails_helper"

# Which reminders leave at a given moment (ADR 0017): the bins at 19:00, followed up at 20:00 and 21:00 when they must
# not be missed, never after 22:00, once for a flexible task.
RSpec.describe RemindersDueQuery do
  let(:household) { create(:household) }
  let(:today) { Date.new(2026, 12, 1) }

  def task(critical: true, reminder_minute: 19 * 60, due_on: today, **attributes)
    task = create(:task, household:, subject: nil, template_key: nil, importance: critical ? :critical : :flexible,
                         reminder_minute:, **attributes)
    task.occurrences.create!(due_at: due_on.in_time_zone)
  end

  def due_at(time, occurrence = nil)
    relation = described_class.new.call(now: Time.zone.parse("2026-12-01 #{time}"))
    occurrence ? relation.include?(occurrence) : relation.to_a
  end

  def sent(occurrence, count, at:)
    occurrence.update!(reminders_sent: count, last_reminded_at: Time.zone.parse("2026-12-01 #{at}"))
  end

  it "is due from the task's time on its day, not before" do
    bins = task

    expect(due_at("18:59", bins)).to be(false)
    expect(due_at("19:00", bins)).to be(true)
    expect(due_at("19:04", bins)).to be(true)
  end

  it "follows a task that must not be missed every hour, three notifications at most" do
    bins = task
    sent(bins, 1, at: "19:00")
    expect(due_at("19:55", bins)).to be(false)
    expect(due_at("20:00", bins)).to be(true)

    sent(bins, 2, at: "20:00")
    expect(due_at("21:00", bins)).to be(true)

    sent(bins, 3, at: "21:00")
    expect(due_at("21:55", bins)).to be(false)
  end

  it "reminds a flexible task once" do
    airing = task(critical: false)
    expect(due_at("19:00", airing)).to be(true)

    sent(airing, 1, at: "19:00")
    expect(due_at("20:30", airing)).to be(false)
  end

  it "sends nothing at 22:00 or after, even late" do
    late = task(reminder_minute: 21 * 60 + 45)

    expect(due_at("21:50", late)).to be(true)
    expect(due_at("22:00", late)).to be(false)
  end

  it "after an outage, sends the late reminder once, then waits an hour before the follow-up" do
    bins = task
    expect(due_at("20:40", bins)).to be(true)

    sent(bins, 1, at: "20:40")
    expect(due_at("21:00", bins)).to be(false) # 20:00 + 1 h passed, but the last one left 20 min ago
    expect(due_at("21:35", bins)).to be(true)
  end

  it "skips the tasks without a reminder, not due today, reopened after a miss, stopped, or no longer open" do
    expect(due_at("19:00", task(reminder_minute: nil))).to be(false)
    expect(due_at("19:00", task(due_on: today + 1))).to be(false)
    expect(due_at("19:00", task(due_on: today - 1))).to be(false)
    reopened = task.tap { _1.update!(reopened_after_miss: true) }
    expect(due_at("19:00", reopened)).to be(false)
    expect(due_at("19:00", task(active: false))).to be(false)
    done = task.tap { _1.update!(status: :done, completed_at: Time.zone.parse("2026-12-01 18:00")) }
    expect(due_at("19:00", done)).to be(false)
  end

  it "keeps a reminder of the morning on its time of the day" do
    early = task(reminder_minute: 7 * 60 + 30)

    expect(due_at("07:29", early)).to be(false)
    expect(due_at("07:30", early)).to be(true)
  end
end
