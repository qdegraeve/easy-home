import { Controller } from "@hotwired/stimulus"

// Saves a settings form as soon as something changes (UX review: "est-ce que c'est enregistré ?"): no button to
// forget before going back. The server answers with a toast only, the form is left as the user set it.
// One request at a time: a change made while a request runs sends the form again once it ends, with every value as
// it is then, so that the last state always wins. Leaving the page with such a change still waiting sends it anyway
// (keepalive request).
// While something is still to save, the form carries data-autosave-pending. A request that fails (no network) keeps
// it and brings the submit button back: the user sees that it is not saved and can try again.
// Without JavaScript, the submit button stays and does the same.
export default class extends Controller {
  static targets = ["submit"]

  connect() {
    this.submitTargets.forEach((button) => (button.hidden = true))
    // A page restored from Turbo's cache has no request running.
    delete this.element.dataset.autosavePending
    this.sending = false
    this.again = false
  }

  disconnect() {
    if (this.again) this.sendOnLeave()
  }

  save() {
    if (this.sending) {
      this.again = true
      return
    }
    this.sending = true
    this.element.dataset.autosavePending = ""
    this.element.requestSubmit()
  }

  // turbo:submit-end
  sent({ detail } = {}) {
    this.sending = false
    if (detail && detail.success === false) {
      this.again = false
      this.submitTargets.forEach((button) => (button.hidden = false))
      return
    }
    if (this.again) {
      this.again = false
      // After Turbo is done with the previous submission, so that its progress shows for this one too.
      setTimeout(() => this.save())
    } else {
      delete this.element.dataset.autosavePending
    }
  }

  sendOnLeave() {
    const token = document.querySelector("meta[name=csrf-token]")?.content
    fetch(this.element.action, {
      method: "POST",
      body: new FormData(this.element),
      keepalive: true,
      headers: { "X-CSRF-Token": token, Accept: "text/vnd.turbo-stream.html" }
    })
  }
}