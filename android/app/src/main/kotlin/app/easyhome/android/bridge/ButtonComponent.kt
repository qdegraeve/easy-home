package app.easyhome.android.bridge

import android.view.Menu
import android.view.MenuItem
import androidx.core.content.ContextCompat
import app.easyhome.android.R
import dev.hotwire.core.bridge.BridgeComponent
import dev.hotwire.core.bridge.BridgeDelegate
import dev.hotwire.core.bridge.Message
import dev.hotwire.navigation.destinations.HotwireDestination
import org.json.JSONObject

// "button" bridge component (app/javascript/controllers/bridge/button_controller.js): the main action of the page as
// a button of the native top bar ("+" to add a plant). Tapping it tells the page, which clicks its own element.
class ButtonComponent(
    name: String,
    private val delegate: BridgeDelegate<HotwireDestination>
) : BridgeComponent<HotwireDestination>(name, delegate) {
    override fun onReceive(message: Message) {
        if (message.event == "connect") showButton(JSONObject(message.jsonData))
    }

    private fun showButton(data: JSONObject) {
        val toolbar = delegate.destination.toolbarForNavigation() ?: return
        val title = data.optString("title")
        val icon = ICONS[data.optString("icon")]

        toolbar.menu.removeItem(ITEM_ID)
        toolbar.menu.add(Menu.NONE, ITEM_ID, Menu.FIRST, title).apply {
            icon?.let { setIcon(ContextCompat.getDrawable(toolbar.context, it)) }
            iconTintList = ContextCompat.getColorStateList(toolbar.context, R.color.ink)
            setShowAsAction(MenuItem.SHOW_AS_ACTION_ALWAYS)
            setOnMenuItemClickListener { replyTo("connect") }
        }
    }

    private companion object {
        const val ITEM_ID = 1001
        val ICONS = mapOf("plus" to R.drawable.ic_plus)
    }
}
