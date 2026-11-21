package app.easyhome.android

import android.graphics.Color
import android.os.Bundle
import android.view.View
import androidx.activity.SystemBarStyle
import androidx.activity.enableEdgeToEdge
import com.google.android.material.bottomnavigation.BottomNavigationView
import dev.hotwire.navigation.activities.HotwireActivity
import dev.hotwire.navigation.tabs.HotwireBottomNavigationController
import dev.hotwire.navigation.tabs.navigatorConfigurations
import dev.hotwire.navigation.util.applyDefaultImeWindowInsets

class MainActivity : HotwireActivity() {
    private val tabs by lazy { mainTabs(this) }
    private lateinit var bottomNavigation: HotwireBottomNavigationController

    override fun onCreate(savedInstanceState: Bundle?) {
        // Dark system bar icons even when the phone is in dark mode: the app is light only for now (themes.xml).
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.light(Color.TRANSPARENT, Color.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.light(Color.TRANSPARENT, Color.TRANSPARENT)
        )
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        // The keyboard pushes the pages up; the bottom navigation keeps itself above the system navigation bar and
        // hides while the keyboard is open or a modal is shown.
        findViewById<View>(R.id.root).applyDefaultImeWindowInsets()

        bottomNavigation = HotwireBottomNavigationController(
            activity = this,
            view = findViewById<BottomNavigationView>(R.id.bottom_nav),
            lazyLoadTabs = true
        )
        bottomNavigation.load(tabs, savedInstanceState?.getInt(SELECTED_TAB) ?: 0)
    }

    override fun onSaveInstanceState(outState: Bundle) {
        super.onSaveInstanceState(outState)
        outState.putInt(SELECTED_TAB, bottomNavigation.view.selectedItemId)
    }

    override fun navigatorConfigurations() = tabs.navigatorConfigurations

    private companion object {
        const val SELECTED_TAB = "selected_tab"
    }
}
