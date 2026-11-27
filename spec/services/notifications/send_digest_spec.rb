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

  it "sends one notification listing the tasks due today or late, the waterings grouped, to each phone of the user" do
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
          body: "Arroser 2 plantes, Pailler le pied (Citronnier)",
          thread_id: "digest",
          data: { path: "/" }
        ),
        device
      ).and have_enqueued_job(ApplicationPushNotificationJob).with(anything, anything, other_phone)
    expect(user.reload.last_digest_on).to eq(today)
  end

  it "lists for a guest only the tasks opened to them (ADR 0019)" do
    guest = create(:household_member, household:, role: :guest)
    guest_phone = create(:push_device, owner: create(:session, user: guest.user))
    lemon = due_plant("Citronnier")
    due_plant("Basilic")
    Members::SetGuestAccess.new.call(member: guest, params: { subjects: [ "Plant:#{lemon.id}" ] })

    expect { described_class.new.call(user: guest.user, today:) }
      .to have_enqueued_job(ApplicationPushNotificationJob)
      .with("ApplicationPushNotification", hash_including(body: "Arroser Citronnier"), guest_phone)

    guest.update!(access_ends_on: Date.new(2026, 11, 15))
    guest.user.update_column(:last_digest_on, nil)
    expect(described_class.new.call(user: guest.user, today:).failure.first).to eq(:nothing_due)
  end

  it "puts the tasks that must not be missed first, and names a single watering" do
    lemon = due_plant("Citronnier")
    create(:task, household:, subject: lemon, title: "Traitement", template_key: nil, importance: :critical,
                  recurrence_type: :once, recurrence_config: { "due_on" => "2026-11-16" })
      .occurrences.create!(due_at: today.in_time_zone)

    expect { described_class.new.call(user:, today:) }
      .to have_enqueued_job(ApplicationPushNotificationJob)
      .with(anything, hash_including(body: "Traitement (Citronnier), arroser Citronnier"), device)
  end

  it "lists only the tasks that must not be missed when the user asked so, and nothing on the other days" do
    user.update!(digest_scope: :critical)
    lemon = due_plant("Citronnier")

    expect(described_class.new.call(user:, today:).failure.first).to eq(:nothing_due)

    user.reload.update!(last_digest_on: nil) # the next day, as it were
    create(:task, household:, subject: lemon, title: "Traitement", template_key: nil, importance: :critical,
                  recurrence_type: :once, recurrence_config: { "due_on" => "2026-11-16" })
      .occurrences.create!(due_at: today.in_time_zone)
    expect { described_class.new.call(user:, today:) }
      .to have_enqueued_job(ApplicationPushNotificationJob)
      .with(anything, hash_including(title: "1 tâche aujourd'hui", body: "Traitement (Citronnier)"), device)
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

  it "names a task without subject by its title, and shortens a long list" do
    15.times do |index|
      create(:task, household:, subject: nil, title: "Tâche numéro #{index}", template_key: nil,
                    recurrence_type: :once, recurrence_config: { "due_on" => "2026-11-16" })
        .occurrences.create!(due_at: today.in_time_zone)
    end

    described_class.new.call(user:, today:)

    body = enqueued_jobs.sole[:args].second["body"]
    expect(body).to start_with("Tâche numéro 0, Tâche numéro 1")
    expect(body).to end_with("...")
    expect(body.length).to eq(described_class::MAX_BODY_LENGTH)
  end

  it "says when a task with a reminder will be recalled: this evening, or at its time" do
    { "Sortir la poubelle jaune" => 19 * 60, "Aérer la cave" => 14 * 60 + 30 }.each do |title, reminder_minute|
      create(:task, household:, subject: nil, title:, template_key: nil, importance: :critical, reminder_minute:,
                    recurrence_type: :once, recurrence_config: { "due_on" => "2026-11-16" })
        .occurrences.create!(due_at: today.in_time_zone)
    end

    described_class.new.call(user:, today:)

    expect(enqueued_jobs.sole[:args].second["body"])
      .to eq("Ce soir 19 h : sortir la poubelle jaune, à 14 h 30 : aérer la cave")
  end

  it "announces no time for a late task, nor for a reminder already past" do
    create(:task, household:, subject: nil, title: "Sortir la poubelle", template_key: nil, reminder_minute: 19 * 60,
                  recurrence_type: :once, recurrence_config: { "due_on" => "2026-11-15" })
      .occurrences.create!(due_at: (today - 1).in_time_zone)
    create(:task, household:, subject: nil, title: "Aérer", template_key: nil, reminder_minute: 7 * 60,
                  recurrence_type: :once, recurrence_config: { "due_on" => "2026-11-16" })
      .occurrences.create!(due_at: today.in_time_zone)

    described_class.new.call(user:, today:)

    expect(enqueued_jobs.sole[:args].second["body"]).to eq("Sortir la poubelle, Aérer")
  end
end
