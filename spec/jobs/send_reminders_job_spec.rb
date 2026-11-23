require "rails_helper"

RSpec.describe SendRemindersJob do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  it "sends the reminders due, once each" do
    household = create(:household)
    user = create(:household_member, household:).user
    create(:push_device, owner: create(:session, user:))
    task = create(:task, household:, subject: nil, template_key: nil, reminder_minute: 19 * 60)
    task.occurrences.create!(due_at: Time.zone.parse("2026-12-01 00:00"))

    travel_to(Time.zone.parse("2026-12-01 19:02")) do
      expect { described_class.perform_now }.to have_enqueued_job(ApplicationPushNotificationJob).once
      expect { described_class.perform_now }.not_to have_enqueued_job(ApplicationPushNotificationJob)
    end
  end
end
