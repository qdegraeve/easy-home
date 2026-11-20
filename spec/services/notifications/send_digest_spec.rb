require "rails_helper"

RSpec.describe Notifications::SendDigest do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household) }
  let(:user) { create(:household_member, household:, role: :member).user }
  let!(:device) { create(:push_device, owner: create(:session, user:)) }
  let(:today) { Date.new(2026, 11, 16) }

  around { |example| travel_to(Time.zone.parse("2026-11-16 08:00")) { example.run } }

  def due_plant(name, household: self.household, last_watered_at: Time.zone.parse("2026-11-13 08:00"))
    create(:plant, :watered, household:, name:, interval_days: 3, last_watered_at:)
  end

  it "sends one notification listing the tasks due today or late, to each phone of the user" do
    lemon = due_plant("Citronnier")
    due_plant("Basilic", last_watered_at: Time.zone.parse("2026-11-10 08:00")) # late
    due_plant("Menthe", last_watered_at: Time.zone.parse("2026-11-15 08:00")) # due on the 18th
    create(:task, household:, subject: lemon, title: "Pailler le pied", template_key: nil, recurrence_type: :once,
                  recurrence_config: { "due_on" => "2026-11-16" }).occurrences.create!(due_at: today.in_time_zone)
    other_phone = create(:push_device, owner: create(:session, user:))

    expect { described_class.new.call(user:, today:) }
      .to have_enqueued_job(ApplicationPushNotificationJob).with(
        "ApplicationPushNotification",
        hash_including(
          title: "3 tâches aujourd'hui",
          body: "Arroser Basilic, arroser Citronnier, Pailler le pied (Citronnier)",
          thread_id: "digest",
          data: { path: "/" }
        ),
        device
      ).and have_enqueued_job(ApplicationPushNotificationJob).with(anything, anything, other_phone)
    expect(user.reload.last_digest_on).to eq(today)
  end

  it "sends nothing when nothing is due, and does not try again the same day" do
    due_plant("Menthe", last_watered_at: Time.zone.parse("2026-11-15 08:00"))

    expect(described_class.new.call(user:, today:).failure.first).to eq(:nothing_due)
    expect(enqueued_jobs).to be_empty
    expect(described_class.new.call(user:, today:).failure.first).to eq(:already_sent)
  end

  it "sends at most one digest a day" do
    due_plant("Citronnier")
    described_class.new.call(user:, today:)

    expect { described_class.new.call(user:, today:) }.not_to have_enqueued_job(ApplicationPushNotificationJob)
  end

  it "only covers the households the user follows and manages" do
    due_plant("Citronnier")
    unfollowed = create(:household_member, user:, role: :member, digest: false).household
    due_plant("Rosier", household: unfollowed)
    guest_of = create(:household_member, user:, role: :guest).household
    due_plant("Ficus", household: guest_of)
    due_plant("Voisin", household: create(:household))

    expect { described_class.new.call(user:, today:) }
      .to have_enqueued_job(ApplicationPushNotificationJob)
      .with(anything, hash_including(title: "1 tâche aujourd'hui", body: "Arroser Citronnier"), device)
  end

  it "skips the tasks of an archived plant" do
    due_plant("Citronnier")
    Plants::Archive.new.call(plant: due_plant("Rosier"))

    expect { described_class.new.call(user:, today:) }
      .to have_enqueued_job(ApplicationPushNotificationJob)
      .with(anything, hash_including(body: "Arroser Citronnier"), device)
  end
end
