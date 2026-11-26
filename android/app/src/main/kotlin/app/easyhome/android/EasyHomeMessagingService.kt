package app.easyhome.android

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

// Receives the push notifications from Firebase (ADR 0012). In the background, Firebase shows them itself; this is
// called only when the app is on screen, where it must show them.
class EasyHomeMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(message: RemoteMessage) {
        val notification = message.notification ?: return
        PushNotifications.show(this, notification.title, notification.body, message.data[PushNotifications.PATH_EXTRA])
    }

    // A renewed token: nothing to do here (no session in a service). The next page of the app sends it to Rails
    // (PushComponent, push_controller.js), as the session does not know it.
    override fun onNewToken(token: String) = Unit
}