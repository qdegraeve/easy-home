require "rails_helper"

RSpec.describe Notifications::SendReminder do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household) }
  let(:user) { create(:household_member, household:, role: :member).user }
  let!(:device) { create(:push_device, owner: create(:session, user:)) }
  let(:bins) do
    task = create(:task, household:, subject: nil, template_key: nil, title: "Sortir la poubelle jaune",
                         importance: :critical, reminder_minute: 19 * 60)
    task.occurrences.create!(due_at: Time.zone.parse("2026-12-01 00:00"))
  end

  around { |example| travel_to(Time.zone.parse("2026-12-01 19:00")) { example.run } }

  it "sends the task to each phone of the members who follow the household, opening its sheet" do
    other_phone = create(:push_device, owner: create(:session, user:))

    expect { described_class.new.call(occurrence: bins) }
      .to have_enqueued_job(ApplicationPushNotificationJob).with(
        "ApplicationPushNotification",
        hash_including(title: "Sortir la poubelle jaune", thread_id: "task-#{bins.task_id}",
                       data: { path: "/tasks/#{bins.task_id}" }),
        device
      ).and have_enqueued_job(ApplicationPushNotificationJob).with(anything, anything, other_phone)
    expect(bins.reload).to have_attributes(reminders_sent: 1, last_reminded_at: Time.current)
  end

  it "says a follow-up, and names the plant or equipment of the task, never its instructions" do
    plant = create(:plant, household:, name: "Citronnier")
    task = create(:task, household:, subject: plant, template_key: nil, title: "Tailler", reminder_minute: 18 * 60,
                         importance: :critical, instructions: "Couper les gourmands.")
    occurrence = task.occurrences.create!(due_at: Time.zone.parse("2026-12-01 00:00"), reminders_sent: 1,
                                          last_reminded_at: 1.hour.ago)

    expect { described_class.new.call(occurrence:) }
      .to have_enqueued_job(ApplicationPushNotificationJob)
      .with(anything, hash_including(title: "Toujours à faire : tailler · Citronnier"), device)
    expect(enqueued_jobs.to_s).not_to include("Couper les gourmands")
  end

  it "reaches a member whose morning digest is off, but neither a guest, a member who unfollowed, nor another home" do
    user.update!(digest_enabled: false)
    guest = create(:household_member, household:, role: :guest).user
    create(:push_device, owner: create(:session, user: guest))
    unfollowing = create(:household_member, household:, role: :member, digest: false).user
    create(:push_device, owner: create(:session, user: unfollowing))
    create(:push_device, owner: create(:session, user: create(:user, :with_household)))

    expect { described_class.new.call(occurrence: bins) }
      .to have_enqueued_job(ApplicationPushNotificationJob).exactly(1).times.with(anything, anything, device)
  end

  it "claims each send once: a second run with the same count, or a closed occurrence, sends nothing" do
    stale = TaskOccurrence.find(bins.id)
    described_class.new.call(occurrence: bins)

    expect { expect(described_class.new.call(occurrence: stale).failure.first).to eq(:already_sent) }
      .not_to have_enqueued_job(ApplicationPushNotificationJob)

    done = bins.reload.tap { _1.update!(status: :done, completed_at: Time.current) }
    expect(described_class.new.call(occurrence: done).failure.first).to eq(:already_sent)
  end

  describe "through the day" do
    def run(at)
      travel_to(Time.zone.parse("2026-12-01 #{at}"))
      Notifications::SendReminders.new.call.value!
    end

    it "stops the follow-ups once postponed, and reminds the next day at the same time" do
      bins
      expect(run("19:00")).to eq(1)
      travel_to(Time.zone.parse("2026-12-01 19:30"))
      Tasks::Postpone.new.call(occurrence: bins, user:)
      expect(run("20:00")).to eq(0)

      travel_to(Time.zone.parse("2026-12-02 18:59"))
      expect(Notifications::SendReminders.new.call.value!).to eq(0)
      travel_to(Time.zone.parse("2026-12-02 19:00"))
      expect(Notifications::SendReminders.new.call.value!).to eq(1)
    end

    it "sends a new reminder time as a new reminder, even when the former one was sent today" do
      bins.task.update!(importance: :flexible, reminder_minute: 8 * 60)
      expect(run("08:00")).to eq(1)

      travel_to(Time.zone.parse("2026-12-01 09:00"))
      task = bins.task
      Tasks::Update.new.call(task:, params: TaskForm.from(task).attributes.merge("reminder_time" => "19:00"))

      expect(run("18:55")).to eq(0)
      expect(run("19:00")).to eq(1)
    end

    it "stops the follow-ups of a task that became flexible after its first reminder" do
      bins
      expect(run("19:00")).to eq(1)
      bins.task.update!(importance: :flexible)

      expect(run("20:00")).to eq(0)
    end
  end
end
