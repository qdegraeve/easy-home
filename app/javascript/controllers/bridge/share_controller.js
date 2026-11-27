import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

// The share sheet of the Android app (see share_controller.js, which decides): sends the text to the "share"
// component of the app. Only loads in the app.
export default class extends BridgeComponent {
  static component = "share"

  share({ detail: { text } }) {
    this.send("share", { text })
  }
}
