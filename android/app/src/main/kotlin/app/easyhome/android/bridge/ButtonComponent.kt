package app.easyhome.android.bridge

import androidx.core.content.ContextCompat
import app.easyhome.android.R
import com.google.android.material.floatingactionbutton.FloatingActionButton
import dev.hotwire.core.bridge.BridgeComponent
import dev.hotwire.core.bridge.BridgeDelegate
import dev.hotwire.core.bridge.Message
import dev.hotwire.navigation.destinations.HotwireDestination
import java.util.WeakHashMap
import org.json.JSONObject

// "button" bridge component (app/javascript/controllers/bridge/button_controller.js): the main action of the page
// ("+" to add a plant) as the floating button of the app, at the bottom right, above the tabs (Android convention:
// the floating button creates, the top bar is for navigation and secondary actions). Tapping it tells the page,
// which clicks its own element.
//
// The button belongs to the page on screen: MainActivity calls showFor() with the destination shown after every
// navigation and tab change; each page remembers what it declared.
class ButtonComponent(
    name: String,
    private val delegate: BridgeDelegate<HotwireDestination>
) : BridgeComponent<HotwireDestination>(name, delegate) {
    private var data: JSONObject? = null

    override fun onReceive(message: Message) {
        if (message.event != "connect") return
        data = JSONObject(message.jsonData)
        declared[delegate.destination] = this
        val button = button() ?: return
        if (button.tag === delegate.destination) show(button) // already the page on screen
    }

    private fun show(button: FloatingActionButton) {
        val data = data ?: return button.hide()
        button.contentDescription = data.optString("title")
        val icon = ICONS[data.optString("icon")] ?: R.drawable.ic_plus
        button.setImageDrawable(ContextCompat.getDrawable(button.context, icon))
        button.setOnClickListener { replyTo("connect") }
        button.show()
    }

    private fun button(): FloatingActionButton? =
        delegate.destination.fragment.activity?.findViewById(R.id.main_action)

    companion object {
        private val ICONS = mapOf("plus" to R.drawable.ic_plus)
        private val declared = WeakHashMap<HotwireDestination, ButtonComponent>()

        // The page now on screen: its button if it declared one, none otherwise. A page that declares its button
        // later (it is still loading) shows it on arrival (onReceive).
        fun showFor(destination: HotwireDestination?, button: FloatingActionButton) {
            button.tag = destination
            val component = destination?.let { declared[it] } ?: return button.hide()
            component.show(button)
        }
    }
}
