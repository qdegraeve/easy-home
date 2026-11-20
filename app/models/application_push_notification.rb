# Push notifications sent through Firebase Cloud Messaging (action_push_native, ADR 0012). Disabled in tests by the
# gem: specs check the enqueued delivery jobs.
class ApplicationPushNotification < ActionPushNative::Notification
end
