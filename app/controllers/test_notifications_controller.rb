# Sends a test notification to the phones of the signed-in user, from the notification settings: the quick way to
# check the whole chain (Rails, Firebase, phone) after a change.
class TestNotificationsController < ApplicationController
  def create
    authorize Current.user, :update?, policy_class: UserPolicy
    devices = Current.user.push_devices.to_a
    return redirect_to(edit_notification_settings_path, alert: t(".no_device")) if devices.empty?

    ApplicationPushNotification.with_data(path: "/")
      .new(title: t(".title"), body: t(".body"))
      .deliver_later_to(devices)
    redirect_to edit_notification_settings_path, notice: t(".success", count: devices.size)
  end
end
