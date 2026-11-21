package app.easyhome.android

import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.view.View
import androidx.activity.OnBackPressedCallback
import androidx.activity.SystemBarStyle
import androidx.activity.enableEdgeToEdge
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.isVisible
import androidx.core.view.updatePadding
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
        }

        applyBottomInsets(bottomNavigationView)
        onBackPressedDispatcher.addCallback(this, backToFirstTab)
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putInt(SELECTED_TAB, bottomNavigation.view.selectedItemId)
    }

    override fun navigatorConfigurations() = tabs.navigatorConfigurations

    override fun onNavigatorReady(navigator: Navigator) {
        navigator.host.navController.addOnDestinationChangedListener { _, _, _ -> onPageChanged(navigator) }
    }

    // Signed out (from the settings, or a session that expired in any tab): no tabs on the sign-in pages, and every
    // tab starts again from "Aujourd'hui". Signed in again: the tabs come back, reloaded for the new session.
    private fun onPageChanged(navigator: Navigator) {
        val path = navigator.location?.let { Uri.parse(it).path } ?: return
        val signInPage = SIGN_IN_PATHS.any { path.startsWith(it) }

        if (signInPage && !signedOut) {
            signedOut = true
            bottomNavigation.visibility = Visibility.HIDDEN
            if (bottomNavigation.view.selectedItemId != 0) {
                bottomNavigation.selectTab(0)
                delegate.resetNavigators()
            }
        } else if (!signInPage && signedOut) {
            signedOut = false
            bottomNavigation.visibility = Visibility.DEFAULT
            delegate.resetNavigators()
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
