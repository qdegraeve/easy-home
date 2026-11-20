package app.easyhome.android

import android.app.Application
import dev.hotwire.core.config.Hotwire
import dev.hotwire.core.logging.HotwireLogLevel
import dev.hotwire.core.turbo.config.PathConfiguration

// Plumbing only: every screen is the Rails app in a web view; the business logic stays in Rails.
class EasyHomeApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        Hotwire.config.webViewDebuggingEnabled = BuildConfig.DEBUG
        Hotwire.config.applicationUserAgentPrefix = "EasyHome Android;"
        Hotwire.config.logger.logLevel = if (BuildConfig.DEBUG) HotwireLogLevel.DEBUG else HotwireLogLevel.NONE

        // Navigation rules: the bundled copy first, then the one served by Rails (cached for the next launch).
        Hotwire.loadPathConfiguration(
            context = this,
            location = PathConfiguration.Location(
                assetFilePath = "json/path-configuration.json",
                remoteFileUrl = "${BuildConfig.BASE_URL}/configurations/android_v1"
            )
        )
    }
}
