# The signed-in user's notification settings (morning digest).
class NotificationSettingsController < ApplicationController
  def edit
    authorize Current.user, policy_class: UserPolicy
    @form = NotificationSettingsForm.from(Current.user)
  end

  def update
    authorize Current.user, policy_class: UserPolicy
    result = Notifications::UpdateSettings.new.call(user: Current.user, params: settings_params)

    if result.success?
      redirect_to edit_notification_settings_path, notice: t(".success")
    else
      _code, @form = result.failure
      render :edit, status: :unprocessable_content
    end
  end

  private

  def settings_params
    params.expect(notification_settings: [ :digest_enabled, :digest_time, :critical_only, household_ids: [] ])
  end
end
