import { BridgeComponent } from "@hotwired/hotwire-native-bridge"
import { Turbo } from "@hotwired/turbo-rails"

// Registers the phone for push notifications (Android app, ADR 0012). The app owns the Firebase token; the page
// sends it to Rails, in the session of the signed-in user (POST /push_devices).
//
// - On every page of the app, the app gives its token when notifications are already allowed (it never asks for the
//   permission there). The page posts it only when the session does not know it yet: its fingerprints (SHA-256 of
//   the tokens of the session) come from Rails. That covers a new session and a token renewed by Firebase.
// - From the Notifications page, "Recevoir les notifications sur ce téléphone" asks the app to request the
//   permission, then registers the phone and reloads the page. Refused: a line explains, with a button that opens
//   the notification settings of the app.
//
//   <div data-controller="bridge--push" data-bridge--push-fingerprints-value="[]"
//        data-bridge--push-url-value="/push_devices" hidden></div>
export default class extends BridgeComponent {
  static component = "push"
  static targets = ["denied", "unavailable"]
  static values = { fingerprints: Array, url: String }

  connect() {
    super.connect()
    this.send("token", {}, ({ data }) => this.register(data))
  }

  enable() {
    this.send("enable", {}, async ({ data }) => {
      this.deniedTargets.forEach((element) => { element.hidden = data.status !== "denied" })
      this.unavailableTargets.forEach((element) => { element.hidden = data.status !== "unavailable" })
      if (data.status !== "granted") return

      await this.register(data)
      Turbo.visit(window.location.href, { action: "replace" })
    })
  }

  openSettings() {
    this.send("openSettings")
  }

  // Posts the token when the session does not know it yet. Returns whether the phone was registered now.
  async register({ status, token, name } = {}) {
    if (status !== "granted" || !token) return false

    const fingerprint = await sha256(token)
    if (this.fingerprintsValue.includes(fingerprint)) return false

    const response = await fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json",
        "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content
      },
      body: JSON.stringify({ push_device: { token, name } })
    })
    if (!response.ok) return false

    this.fingerprintsValue = [...this.fingerprintsValue, fingerprint]
    return true
  }
}

async function sha256(text) {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text))
  return Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, "0")).join("")
}