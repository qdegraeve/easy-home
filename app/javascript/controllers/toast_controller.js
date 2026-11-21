import { Controller } from "@hotwired/stimulus"

// A message at the bottom of the screen that never moves the page (UX review, "Toast"). A confirmation goes away by
// itself after `duration` ms; an error stays until closed, so that it can be read.
// Screen readers: the toast arrives with the page, already filled, and a live region inserted that way is often not
// read. The text is copied into the permanent live region of the layout (#announcer), which does get read.
export default class extends Controller {
  static targets = ["message"]
  static values = { duration: Number, assertive: Boolean }

  // The countdown pauses while the toast is pointed at or has the focus, so that "Annuler" stays reachable (keyboard,
  // screen reader, slow finger), then starts again from the beginning.
  connect() {
    this.start()
    this.pause = () => clearTimeout(this.timer)
    this.resume = () => this.start()
    this.element.addEventListener("pointerenter", this.pause)
    this.element.addEventListener("focusin", this.pause)
    this.element.addEventListener("pointerleave", this.resume)
    this.element.addEventListener("focusout", this.resume)
    this.announce()
  }

  // Leaving the page (or the toast closing) takes the message out of the permanent live region too: it would
  // otherwise stay there, read again, on the next pages.
  disconnect() {
    clearTimeout(this.timer)
    clearTimeout(this.announceTimer)
    this.forget()
  }

  start() {
    clearTimeout(this.timer)
    if (this.durationValue > 0) this.timer = setTimeout(() => this.close(), this.durationValue)
  }

  // Closed by hand or by time: the live region forgets the message too.
  close() {
    this.forget()
    this.element.remove()
  }

  forget() {
    const announcer = document.getElementById("announcer")
    if (announcer?.textContent === this.text) announcer.textContent = ""
  }

  get text() {
    return (this.hasMessageTarget ? this.messageTarget : this.element).textContent.trim()
  }

  // Looked up after a tick: during a Turbo visit, the permanent region is put back in the page after the controllers
  // of the new page connect. Emptied then filled, so that the region announces even the same message again.
  announce() {
    const text = this.text

    this.announceTimer = setTimeout(() => {
      const announcer = document.getElementById("announcer")
      if (!announcer) return

      announcer.setAttribute("aria-live", this.assertiveValue ? "assertive" : "polite")
      announcer.textContent = ""
      this.announceTimer = setTimeout(() => { announcer.textContent = text }, 100)
    }, 0)
  }
}