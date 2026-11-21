import { Controller } from "@hotwired/stimulus"

// A message at the bottom of the screen that never moves the page (UX review, "Toast"). A confirmation goes away by
// itself after `duration` ms; an error stays until closed, so that it can be read.
export default class extends Controller {
  static values = { duration: Number }

  connect() {
    if (this.durationValue > 0) this.timer = setTimeout(() => this.close(), this.durationValue)
  }

  disconnect() {
    clearTimeout(this.timer)
  }

  close() {
    this.element.remove()
  }
}