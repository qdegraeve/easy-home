package app.easyhome.android

import android.Manifest
import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import androidx.activity.OnBackPressedCallback
import androidx.activity.SystemBarStyle
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.contract.ActivityResultContracts.RequestPermission
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.isVisible
import androidx.core.view.updatePadding
import app.easyhome.android.bridge.ButtonComponent
import com.google.android.material.bottomnavigation.BottomNavigationView
import dev.hotwire.navigation.activities.HotwireActivity
import dev.hotwire.navigation.navigator.Navigator
import dev.hotwire.navigation.tabs.HotwireBottomNavigationController
import dev.hotwire.navigation.tabs.HotwireBottomNavigationController.Visibility
import dev.hotwire.navigation.tabs.navigatorConfigurations
import dev.hotwire.navigation.util.applyDefaultImeWindowInsets

class MainActivity : HotwireActivity() {
    private val tabs by lazy { mainTabs(this) }
    private lateinit var bottomNavigation: HotwireBottomNavigationController
    private lateinit var navigatorHosts: View
    private var signedOut = false
    private val navigators = mutableMapOf<String, Navigator>()

    // Notification permission (Android 13+), asked by the "push" bridge component when the user turns notifications
    // on. Registered with the activity, as Android requires; the answer goes to the component that asked.
    private var onNotificationPermission: ((Boolean) -> Unit)? = null
    private val notificationPermission = registerForActivityResult(RequestPermission()) { granted ->
        onNotificationPermission?.invoke(granted)
        onNotificationPermission = null
    }

    // The page of a tapped notification, opened once the "Aujourd'hui" tab is ready (cold start).
    private var pendingNotificationPath: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // Dark system bar icons even when the phone is in dark mode: the app is light only for now (themes.xml).
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.light(Color.TRANSPARENT, Color.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.light(Color.TRANSPARENT, Color.TRANSPARENT)
        )
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        navigatorHosts = findViewById(R.id.navigator_hosts)

        val bottomNavigationView = findViewById<BottomNavigationView>(R.id.bottom_nav)
        bottomNavigation = HotwireBottomNavigationController(
            activity = this,
            view = bottomNavigationView,
            lazyLoadTabs = true
        )
        bottomNavigation.load(tabs, savedInstanceState?.getInt(SELECTED_TAB) ?: 0)
        // Each tab keeps its own page: refreshed when it comes back, so that a watering done in "Aujourd'hui" shows in
        // "Journal" without pulling down. (A tab shown for the first time loads anyway: no destination yet.)
        bottomNavigation.setOnTabSelectedListener { _, _ ->
            delegate.currentNavigator?.currentDestination?.refresh(displayProgress = false)
            updateMainAction()
        }

        applyBottomInsets(bottomNavigationView)
        onBackPressedDispatcher.addCallback(this, backToFirstTab)
        if (savedInstanceState == null) pendingNotificationPath = PushNotifications.pathOf(intent)
    }

    // A notification tapped while the app runs (single instance): its page, in "Aujourd'hui".
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        PushNotifications.pathOf(intent)?.let(::openFromNotification)
    }

    fun requestNotificationPermission(callback: (Boolean) -> Unit) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return callback(PushNotifications.permitted(this))

        onNotificationPermission = callback
        notificationPermission.launch(Manifest.permission.POST_NOTIFICATIONS)
    }

    // "Aujourd'hui" back to its start page, then the notification's page on top of it (the digest points to "/",
    // the start page itself: refreshed).
    private fun openFromNotification(path: String) {
        bottomNavigation.selectTab(0)
        navigatorHosts.post {
            val navigator = delegate.currentNavigator ?: return@post
            navigator.clearAll {
                if (path == "/") {
                    navigator.currentDestination?.refresh(displayProgress = false)
                } else {
                    navigator.route(BuildConfig.BASE_URL.trimEnd('/') + path)
                }
            }
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putInt(SELECTED_TAB, bottomNavigation.view.selectedItemId)
    }

    override fun navigatorConfigurations() = tabs.navigatorConfigurations

    override fun onNavigatorReady(navigator: Navigator) {
        navigators[navigator.configuration.name] = navigator
        navigator.host.navController.addOnDestinationChangedListener { _, _, _ ->
            onPageChanged(navigator)
            updateMainAction()
        }
        // Opened from a notification: its page once "Aujourd'hui" exists (its start page loads first anyway).
        if (navigator.configuration.name == tabs.first().configuration.name) {
            pendingNotificationPath?.takeIf { it != "/" }?.let { path ->
                navigatorHosts.post { navigator.route(BuildConfig.BASE_URL.trimEnd('/') + path) }
            }
            pendingNotificationPath = null
        }
    }

    // Signed out (from the settings, or a session that expired): no tabs on the sign-in pages. Signed in again: the
    // tabs come back. Only the page shown counts: the other tabs load pages in the background (their
    // start page, a redirection to the sign-in page) that say nothing about the user signing in or out.
    private fun onPageChanged(navigator: Navigator) {
        if (navigator != delegate.currentNavigator) return
        val path = navigator.location?.let { Uri.parse(it).path } ?: return
        val signInPage = SIGN_IN_PATHS.any { path.startsWith(it) }

        if (signInPage && !signedOut) {
            signedOut = true
            bottomNavigation.visibility = Visibility.HIDDEN
        } else if (!signInPage && signedOut) {
            signedOut = false
            bottomNavigation.visibility = Visibility.DEFAULT
            // Every tab starts over from its own start page for the new session, the one shown included: signing in
            // from "Maison" lands on the home page, which must not become the root of "Maison". After the current
            // navigation ends (posted).
            navigatorHosts.post { delegate.resetNavigators() }
        }
    }

    // The floating button of the page on screen (bridge "button"), once the navigation has settled (posted): the new
    // destination is then the current one of the current tab.
    private fun updateMainAction() {
        navigatorHosts.post {
            ButtonComponent.showFor(delegate.currentNavigator?.currentDestination, this)
        }
    }

    // "Back" at the start page of "Maison" or "Journal" returns to "Aujourd'hui" instead of leaving the app; inside a
    // tab, the usual "back" of the tab's stack (Hotwire's own callback, registered before this one).
    private val backToFirstTab = object : OnBackPressedCallback(true) {
        override fun handleOnBackPressed() {
            val navigator = delegate.currentNavigator
            if (bottomNavigation.view.selectedItemId != 0 && navigator?.isAtStartDestination() == true) {
                bottomNavigation.selectTab(0)
            } else {
                isEnabled = false
                onBackPressedDispatcher.onBackPressed()
                isEnabled = true
            }
        }
    }

    // The keyboard pushes the pages up. The tab bar keeps itself above the system navigation bar; when it is hidden
    // (a modal), the pages take that space themselves, so that their bottom (toasts, buttons) stays visible.
    private fun applyBottomInsets(bottomNavigationView: View) {
        findViewById<View>(R.id.root).applyDefaultImeWindowInsets()
        ViewCompat.setOnApplyWindowInsetsListener(navigatorHosts) { view, insets ->
            val keyboard = insets.isVisible(WindowInsetsCompat.Type.ime())
            val navigationBar = insets.getInsets(WindowInsetsCompat.Type.navigationBars()).bottom
            view.updatePadding(bottom = if (keyboard || bottomNavigationView.isVisible) 0 else navigationBar)
            insets
        }
        var tabsVisible = bottomNavigationView.isVisible
        bottomNavigationView.viewTreeObserver.addOnGlobalLayoutListener {
            if (bottomNavigationView.isVisible != tabsVisible) {
                tabsVisible = bottomNavigationView.isVisible
                ViewCompat.requestApplyInsets(navigatorHosts)
            }
        }
    }

    private companion object {
        const val SELECTED_TAB = "selected_tab"
        val SIGN_IN_PATHS = listOf("/session/new", "/passwords")
    }
}
