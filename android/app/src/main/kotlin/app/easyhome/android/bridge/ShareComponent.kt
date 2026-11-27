package app.easyhome.android.bridge

import android.content.Intent
import dev.hotwire.core.bridge.BridgeComponent
import dev.hotwire.core.bridge.BridgeDelegate
import dev.hotwire.core.bridge.Message
import dev.hotwire.navigation.destinations.HotwireDestination
import org.json.JSONObject

// "share" bridge component (app/javascript/controllers/bridge/share_controller.js): the share sheet of Android for a
// text, here the link of an invitation (ADR 0019). The WebView has no Web Share API, hence this component.
class ShareComponent(
    name: String,
    private val delegate: BridgeDelegate<HotwireDestination>
) : BridgeComponent<HotwireDestination>(name, delegate) {
    override fun onReceive(message: Message) {
        if (message.event != "share") return

        val text = JSONObject(message.jsonData).optString("text").ifBlank { return }
        val activity = delegate.destination.fragment.activity ?: return
        val send = Intent(Intent.ACTION_SEND).setType("text/plain").putExtra(Intent.EXTRA_TEXT, text)
        activity.startActivity(Intent.createChooser(send, null))
    }
}
