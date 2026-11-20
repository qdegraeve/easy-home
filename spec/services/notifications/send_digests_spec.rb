require "rails_helper"

RSpec.describe Notifications::SendDigests do
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers

  let(:household) { create(:household) }
  let(:user) { create(:household_member, household:, role: :member).user }

  around { |example| travel_to(Time.zone.parse("2026-11-16 07:50")) { example.run } }

  before do
    create(:plant, :watered, household:, interval_days: 3, last_watered_at: Time.zone.parse("2026-11-13 08:00"))
    create(:push_device, owner: create(:session, user:))
  end

  it "sends the digest once its time has come, then not again the same day" do
    expect(described_class.new.call.value!).to eq(0)

    travel_to(Time.zone.parse("2026-11-16 08:03"))
    expect(described_class.new.call.value!).to eq(1)
    expect(described_class.new.call.value!).to eq(0)

    travel_to(Time.zone.parse("2026-11-17 08:00"))
    expect(described_class.new.call.value!).to eq(1)
  end

  it "gives up on a digest more than two hours late: it is a morning digest" do
    travel_to(Time.zone.parse("2026-11-16 10:01"))

    expect(described_class.new.call.value!).to eq(0)
  end

  it "follows the time chosen by the user, in the app time zone" do
    user.update!(digest_minute: 6 * 60 + 45)

    expect(described_class.new.call.value!).to eq(1)
  end

  it "sends nothing to a user who turned the digest off" do
    user.update!(digest_enabled: false)
    travel_to(Time.zone.parse("2026-11-16 09:00"))

    expect(described_class.new.call.value!).to eq(0)
    expect(user.reload.last_digest_on).to be_nil
  end

  it "skips the users without any phone" do
    Session.where(user:).destroy_all
    travel_to(Time.zone.parse("2026-11-16 09:00"))

    expect(described_class.new.call.value!).to eq(0)
    expect(user.reload.last_digest_on).to be_nil
  end
end
