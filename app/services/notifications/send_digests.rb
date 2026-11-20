module Notifications
  # Sends the morning digests whose time has come today: users who enabled them, with at least one phone, and no
  # digest sent yet today. Run every few minutes by SendDigestsJob, so a digest leaves within minutes of its time.
  class SendDigests
    include Dry::Monads[:result]

    def call(now: Time.current)
      today = now.to_date
      minute = (now.hour * 60) + now.min
      users = User.where(digest_enabled: true, digest_minute: ..minute)
        .where("last_digest_on IS NULL OR last_digest_on < ?", today)
        .where(id: Session.joins(:push_devices).select(:user_id))

      Success(users.find_each.count { |user| SendDigest.new.call(user:, today:).success? })
    end
  end
end
