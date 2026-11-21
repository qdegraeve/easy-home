package app.easyhome.android

import android.net.Uri
import android.os.Bundle
import android.view.View
import dev.hotwire.core.turbo.config.context
import dev.hotwire.core.turbo.nav.PresentationContext
import dev.hotwire.navigation.destinations.HotwireDestinationDeepLink
import dev.hotwire.navigation.fragments.HotwireWebFragment

// Every web screen of the app, with the settings in its native top bar, so that they are always at hand. Not on the
// settings themselves, nor on the sign-in pages, nor in a modal (its top bar is for closing it).
@HotwireDestinationDeepLink(uri = "hotwire://fragment/web")
class WebFragment : HotwireWebFragment() {
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        if (showsSettings()) addSettingsButton()
    }

    private fun showsSettings(): Boolean {
        val path = Uri.parse(location).path.orEmpty()
        val modal = pathProperties.context == PresentationContext.MODAL
        return !modal && NO_SETTINGS_PATHS.none { path.startsWith(it) }
    }

    private fun addSettingsButton() {
        val toolbar = toolbarForNavigation() ?: return
        toolbar.inflateMenu(R.menu.web)
        toolbar.setOnMenuItemClickListener { item ->
            if (item.itemId != R.id.settings) return@setOnMenuItemClickListener false
            navigator.route("${BuildConfig.BASE_URL.trimEnd('/')}/settings")
            true
        }
    }

    private companion object {
        val NO_SETTINGS_PATHS = listOf("/settings", "/session", "/passwords")
    }
}
