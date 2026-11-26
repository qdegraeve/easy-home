package app.easyhome.android.bridge

import android.content.Intent
import android.os.Build
import android.provider.Settings
import app.easyhome.android.MainActivity
import app.easyhome.android.PushNotifications
import com.google.firebase.messaging.FirebaseMessaging
import dev.hotwire.core.bridge.BridgeComponent
import dev.hotwire.core.bridge.BridgeDelegate
import dev.hotwire.core.bridge.Message
import dev.hotwire.navigation.destinations.HotwireDestination
import org.json.JSONObject

// "push" bridge component (app/javascript/controllers/bridge/push_controller.js, ADR 0012): gives the page the
// Firebase token of the phone, which the page sends to Rails in the user's session. Every reply carries a status:
// "granted" (with the token and the phone's name), "prompt" (permission not given), "denied" (refused when asked),
// "unavailable" (app built without Firebase, or no token).
//
// - "token": sent by every page; never asks for the permission.
// - "enable": the user's own move on the Notifications page; asks for the permission first if needed.
// - "openSettings": the notification settings of the app, after a refusal.
class PushComponent(
    name: String,
    private val delegate: BridgeDelegate<HotwireDestination>
) : BridgeComponent<HotwireDestination>(name, delegate) {
    override fun onReceive(message: Message) {
        when (message.event) {
            "token" -> replyWithToken("token", ifNotPermitted = "prompt")
            "enable" -> enable()
            "openSettings" -> openSettings()
        }
    }

    private val activity get() = delegate.destination.fragment.activity as? MainActivity

    private fun enable() {
        val activity = activity ?: return
        if (PushNotifications.permitted(activity)) return replyWithToken("enable", ifNotPermitted = "denied")

        activity.requestNotificationPermission { granted ->
            if (granted) replyWithToken("enable", ifNotPermitted = "denied") else reply("enable", "denied")
        }
    }

    private fun replyWithToken(event: String, ifNotPermitted: String) {
        val activity = activity ?: return
        if (!PushNotifications.available(activity)) return reply(event, "unavailable")
        if (!PushNotifications.permitted(activity)) return reply(event, ifNotPermitted)

        FirebaseMessaging.getInstance().token.addOnCompleteListener { task ->
            val token = if (task.isSuccessful) task.result else null // result throws on a failed task
            if (token.isNullOrBlank()) return@addOnCompleteListener reply(event, "unavailable")

            val data = JSONObject().put("status", "granted").put("token", token).put("name", Build.MODEL)
            replyTo(event, data.toString())
        }
    }

    private fun reply(event: String, status: String) {
        replyTo(event, JSONObject().put("status", status).toString())
    }

    private fun openSettings() {
        val activity = activity ?: return
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
            .putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName)
        activity.startActivity(intent)
    }
}