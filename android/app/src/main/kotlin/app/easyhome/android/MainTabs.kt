package app.easyhome.android

import android.content.Context
import dev.hotwire.navigation.navigator.NavigatorConfiguration
import dev.hotwire.navigation.tabs.HotwireBottomTab

// The three sections of the app (UX review): one native tab each, with its own navigation stack. Their start pages
// are Rails routes: /, /house, /journal.
fun mainTabs(context: Context) = listOf(
    tab(context, R.string.tab_today, R.drawable.ic_tab_today, "today", R.id.today_navigator_host, ""),
    tab(context, R.string.tab_house, R.drawable.ic_tab_house, "house", R.id.house_navigator_host, "house"),
    tab(context, R.string.tab_journal, R.drawable.ic_tab_journal, "journal", R.id.journal_navigator_host, "journal")
)

private fun tab(context: Context, title: Int, icon: Int, name: String, hostId: Int, path: String) = HotwireBottomTab(
    title = context.getString(title),
    iconResId = icon,
    configuration = NavigatorConfiguration(
        name = name,
        startLocation = BuildConfig.BASE_URL.trimEnd('/') + "/" + path,
        navigatorHostId = hostId
    )
)
