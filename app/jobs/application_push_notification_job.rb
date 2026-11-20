# Delivers one push notification to one device (action_push_native). Retries and dead tokens are handled by the gem.
class ApplicationPushNotificationJob < ActionPushNative::NotificationJob
  self.report_job_retries = true
end
