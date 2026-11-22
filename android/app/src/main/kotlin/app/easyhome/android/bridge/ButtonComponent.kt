package app.easyhome.android.bridge

import android.app.Activity
import androidx.core.content.ContextCompat
import app.easyhome.android.R
import com.google.android.material.floatingactionbutton.ExtendedFloatingActionButton
import dev.hotwire.core.bridge.BridgeComponent
import dev.hotwire.core.bridge.BridgeDelegate
import dev.hotwire.core.bridge.Message
import dev.hotwire.navigation.destinations.HotwireDestination
import java.lang.ref.WeakReference
import java.util.WeakHashMap
import org.json.JSONObject

// "button" bridge component (app/javascript/controllers/bridge/button_controller.js): the actions of the page as the
// floating buttons of the app, at the bottom right, above the tabs (Android convention: the floating button creates,
// the top bar is for navigation and secondary actions), with an icon and a word ("+ Tâche"). The one of lowest order
// is the main button, at the bottom; a second one sits above it ("Analyse"). Tapping one tells the page, which clicks
// its own element.
//
// The buttons belong to the page on screen: MainActivity calls showFor() with the destination shown after every
// navigation and tab change; each page remembers what it declared.
class ButtonComponent(
    name: String,
    private val delegate: BridgeDelegate<HotwireDestination>
) : BridgeComponent<HotwireDestination>(name, delegate) {
    // The "connect" messages of the page, one per declared button, in the page's order (by element, so that a
    // button that connects again replaces itself).
    private val declaredButtons = linkedMapOf<String, Message>()

    override fun onReceive(message: Message) {
        val data = JSONObject(message.jsonData)
        when (message.event) {
            "connect" -> declaredButtons[data.optString("key", message.id)] = message
            "disconnect" -> declaredButtons.remove(data.optString("key"))
            else -> return
        }
        declared[delegate.destination] = WeakReference(this)
        val activity = delegate.destination.fragment.activity ?: return
        if (activity.mainAction().tag === delegate.destination) show(activity) // already the page on screen
    }

    private fun show(activity: Activity) {
        val buttons = declaredButtons.values.sortedBy { JSONObject(it.jsonData).optInt("order", 1) }
        show(activity.mainAction(), buttons.getOrNull(0))
        show(activity.secondAction(), buttons.getOrNull(1))
    }

    private fun show(button: ExtendedFloatingActionButton, message: Message?) {
        if (message == null) return button.hide()
        val data = JSONObject(message.jsonData)
        // The label says what the button does ("Tâche"); the description, for screen readers, says it in full.
        button.text = data.optString("label").ifBlank { data.optString("title") }
        button.contentDescription = data.optString("title")
        val icon = ICONS[data.optString("icon")] ?: R.drawable.ic_plus
        button.icon = ContextCompat.getDrawable(button.context, icon)
        button.setOnClickListener { replyWith(message) }
        button.show()
    }

    companion object {
        private val ICONS = mapOf("plus" to R.drawable.ic_plus, "analysis" to R.drawable.ic_analysis)

        // Weak both ways: the component holds its destination, so a strong value would keep every page alive.
        private val declared = WeakHashMap<HotwireDestination, WeakReference<ButtonComponent>>()

        private fun Activity.mainAction(): ExtendedFloatingActionButton = findViewById(R.id.main_action)
        private fun Activity.secondAction(): ExtendedFloatingActionButton = findViewById(R.id.second_action)

        // The page now on screen: its buttons if it declared some, none otherwise. A page that declares its buttons
        // later (it is still loading) shows them on arrival (onReceive).
        fun showFor(destination: HotwireDestination?, activity: Activity) {
            activity.mainAction().tag = destination
            val component = destination?.let { declared[it]?.get() }
            if (component == null) {
                activity.mainAction().hide()
                activity.secondAction().hide()
            } else {
                component.show(activity)
            }
        }

        // The page is loaded again from scratch (its scripts and replies are gone): it declares its buttons again, or
        // none.
        fun forget(destination: HotwireDestination) {
            declared.remove(destination)?.get()?.declaredButtons?.clear()
        }
    }
}
