package app.easyhome.android

import android.app.Application
import app.easyhome.android.bridge.ButtonComponent
import app.easyhome.android.bridge.MenuComponent
import app.easyhome.android.bridge.PushComponent
import dev.hotwire.core.bridge.BridgeComponentFactory
import dev.hotwire.core.config.Hotwire
import dev.hotwire.core.logging.HotwireLogLevel
import dev.hotwire.core.turbo.config.PathConfiguration
import dev.hotwire.navigation.config.defaultFragmentDestination
import dev.hotwire.navigation.config.registerBridgeComponents
import dev.hotwire.navigation.config.registerFragmentDestinations

// Plumbing only: every screen is the Rails app in a web view; the business logic stays in Rails.
class EasyHomeApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // Our web screen (settings button in the top bar) instead of Hotwire's default one.
        Hotwire.defaultFragmentDestination = WebFragment::class
        Hotwire.registerFragmentDestinations(WebFragment::class)
        // Native parts of the pages, driven by the web (app/javascript/controllers/bridge/).
        Hotwire.registerBridgeComponents(
            BridgeComponentFactory("button", ::ButtonComponent),
            BridgeComponentFactory("menu", ::MenuComponent),
            BridgeComponentFactory("push", ::PushComponent)
        )
        PushNotifications.createChannel(this)

        Hotwire.config.webViewDebuggingEnabled = BuildConfig.DEBUG
        Hotwire.config.applicationUserAgentPrefix = "EasyHome Android;"
        Hotwire.config.logger.logLevel = if (BuildConfig.DEBUG) HotwireLogLevel.DEBUG else HotwireLogLevel.NONE

        // Navigation rules: the bundled copy first, then the cached one, then the one served by Rails (downloaded in
        // the background, then cached).
        Hotwire.loadPathConfiguration(
            context = this,
            location = PathConfiguration.Location(
                assetFilePath = "json/path-configuration.json",
                remoteFileUrl = "${BuildConfig.BASE_URL}/configurations/android_v1"
            )
        )
    }
}
