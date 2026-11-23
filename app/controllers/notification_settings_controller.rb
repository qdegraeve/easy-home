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
      respond_to do |format|
        # Saved on each change: only the toast, the form is left as the user set it.
        format.turbo_stream do
          flash.now[:notice] = t(".success")
          render turbo_stream: turbo_stream.replace("toasts", partial: "layouts/flash")
        end
        format.html { redirect_to edit_notification_settings_path, notice: t(".success") }
      end
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
