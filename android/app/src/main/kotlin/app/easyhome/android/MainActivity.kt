package app.easyhome.android

import android.graphics.Color
import android.os.Bundle
import android.view.View
import androidx.activity.SystemBarStyle
import androidx.activity.enableEdgeToEdge
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.updatePadding
import dev.hotwire.navigation.activities.HotwireActivity
import dev.hotwire.navigation.navigator.NavigatorConfiguration

class MainActivity : HotwireActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Dark system bar icons even when the phone is in dark mode: the app is light only for now (themes.xml).
        enableEdgeToEdge(
            statusBarStyle = SystemBarStyle.light(Color.TRANSPARENT, Color.TRANSPARENT),
            navigationBarStyle = SystemBarStyle.light(Color.TRANSPARENT, Color.TRANSPARENT)
        )
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        // Keep the pages above the system navigation bar and the keyboard: the app is drawn edge to edge, and the
        // bottom of a page (toasts, last buttons) would otherwise slide under the navigation bar.
        ViewCompat.setOnApplyWindowInsetsListener(findViewById<View>(R.id.main_nav_host)) { view, insets ->
            val bottom = insets.getInsets(WindowInsetsCompat.Type.navigationBars() or WindowInsetsCompat.Type.ime())
            view.updatePadding(bottom = bottom.bottom)
            insets
        }
    }

    override fun navigatorConfigurations() = listOf(
        NavigatorConfiguration(
            name = "main",
            startLocation = BuildConfig.BASE_URL,
            navigatorHostId = R.id.main_nav_host
        )
    )
}
