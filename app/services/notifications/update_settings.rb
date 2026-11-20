module Notifications
  # Saves the user's notification settings: the digest switch and time on the user, the followed households on the
  # memberships.
  class UpdateSettings
    include Dry::Monads[:result, :do]

    def call(user:, params:)
      form = yield validate(user, params)
      save(user, form)

      Success(user)
    end

    private

    def validate(user, params)
      form = NotificationSettingsForm.new(params.to_h.merge(user:))
      form.valid? ? Success(form) : Failure[:invalid, form]
    end

    def save(user, form)
      ActiveRecord::Base.transaction do
        user.update!(digest_enabled: form.digest_enabled, digest_minute: form.digest_minute)
        form.memberships.each do |membership|
          membership.update!(digest: form.household_ids.include?(membership.household_id))
        end
      end
    end
  end
end
