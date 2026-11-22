import { Controller } from "@hotwired/stimulus"

// Saves a settings form as soon as something changes (UX review: "est-ce que c'est enregistré ?"): no button to
// forget before going back. The server answers with a toast only, the form is left as the user set it.
// One request at a time: a change made while a request runs sends the form again once it ends, with every value as
// it is then, so that the last state always wins.
// While something is still to save, the form carries data-autosave-pending (leaving the page then could lose it).
// Without JavaScript, the submit button stays and does the same.
export default class extends Controller {
  static targets = ["submit"]

  connect() {
    this.submitTargets.forEach((button) => (button.hidden = true))
    this.sending = false
    this.again = false
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
  sent() {
    this.sending = false
    if (this.again) {
      this.again = false
      this.save()
    } else {
      delete this.element.dataset.autosavePending
    }
  }
}