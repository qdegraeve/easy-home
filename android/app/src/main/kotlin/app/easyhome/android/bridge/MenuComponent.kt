package app.easyhome.android.bridge

import android.view.Menu
import android.view.MenuItem
import dev.hotwire.core.bridge.BridgeComponent
import dev.hotwire.core.bridge.BridgeDelegate
import dev.hotwire.core.bridge.Message
import dev.hotwire.navigation.destinations.HotwireDestination
import org.json.JSONObject

// "menu" bridge component (app/javascript/controllers/bridge/menu_controller.js): the secondary actions of the page
// (edit, archive, delete a plant) in the "⋮" overflow menu of the native top bar. Choosing one tells the page which,
// and the page clicks its element (its confirmation, if any, shows as usual).
class MenuComponent(
    name: String,
    private val delegate: BridgeDelegate<HotwireDestination>
) : BridgeComponent<HotwireDestination>(name, delegate) {
    override fun onReceive(message: Message) {
        if (message.event == "connect") showItems(JSONObject(message.jsonData))
    }

    private fun showItems(data: JSONObject) {
        val toolbar = delegate.destination.toolbarForNavigation() ?: return
        val items = data.optJSONArray("items") ?: return

        toolbar.menu.removeGroup(GROUP_ID)
        for (position in 0 until items.length()) {
            val item = items.getJSONObject(position)
            val index = item.getInt("index")
            toolbar.menu.add(GROUP_ID, Menu.NONE, Menu.CATEGORY_SECONDARY + position, item.getString("title")).apply {
                setShowAsAction(MenuItem.SHOW_AS_ACTION_NEVER)
                setOnMenuItemClickListener { replyTo("connect", """{"selectedIndex":$index}""") }
            }
        }
    }

    private companion object {
        const val GROUP_ID = 2001
    }
}
