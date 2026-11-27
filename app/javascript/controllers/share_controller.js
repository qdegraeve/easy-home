import { Controller } from "@hotwired/stimulus"

// "Partager" a text (the link of an invitation, ADR 0019). In the Android app, the share sheet of Android: the
// WebView has no Web Share API, so the page asks the "share" bridge component (bridge--share, which only loads in
// the app) through a "share:native" event. In a browser, its own share sheet. Without either, the button hides:
// "Copier" stays.
//
//   <button data-controller="share bridge--share" data-share-text-value="https://…"
//           data-action="share#share share:native->bridge--share#share">Partager</button>
export default class extends Controller {
  static values = { text: String }

  connect() {
    this.element.hidden = !this.native && !navigator.share
  }

  share() {
    if (this.native) {
      this.dispatch("native", { detail: { text: this.textValue } })
    } else {
      navigator.share({ text: this.textValue }).catch(() => {}) // closed without sharing
    }
  }

  // Set by the bridge when the app supports the component.
  get native() {
    return (document.documentElement.dataset.bridgeComponents || "").split(" ").includes("share")
  }
}
