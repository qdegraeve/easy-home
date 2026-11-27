package app.easyhome.android

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.google.firebase.FirebaseApp

// Push notifications (ADR 0012): what the app knows about them. Rails decides what to send and when; the app only
// registers the phone (PushComponent), shows what arrives and opens the page it points to.
object PushNotifications {
    const val CHANNEL_ID = "reminders" // also the default channel of Firebase (AndroidManifest.xml)
    const val PATH_EXTRA = "path" // data of the notification: the page to open (data.path on the Rails side)

    // Firebase is configured only when app/google-services.json was there at build time.
    fun available(context: Context) = FirebaseApp.getApps(context).isNotEmpty()

    // Android 13+ asks for a permission; before, notifications are allowed unless turned off in the settings.
    fun permitted(context: Context) = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
    } else {
        NotificationManagerCompat.from(context).areNotificationsEnabled()
    }

    // The channel the user sees in the settings of the app ("Rappels"), created at every start (no-op when known).
    fun createChannel(context: Context) {
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.notification_channel_reminders),
            NotificationManager.IMPORTANCE_HIGH
        ).apply { description = context.getString(R.string.notification_channel_reminders_description) }
        context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    // A notification received while the app is on screen: Firebase does not show it, the app does.
    fun show(context: Context, title: String?, body: String?, path: String?) {
        if (!permitted(context)) return

        val intent = Intent(context, MainActivity::class.java).putExtra(PATH_EXTRA, path)
        val pendingIntent = PendingIntent.getActivity(
            context,
            System.currentTimeMillis().toInt(),
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(ContextCompat.getColor(context, R.color.brand))
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()
        try {
            NotificationManagerCompat.from(context).notify(System.currentTimeMillis().toInt(), notification)
        } catch (_: SecurityException) {
            // Permission withdrawn in between: nothing to show.
        }
    }

    // The page a notification points to, when it is one of the app's own paths (never another site).
    fun pathOf(intent: Intent?): String? =
        intent?.getStringExtra(PATH_EXTRA)?.takeIf { it.startsWith("/") && !it.startsWith("//") }
}