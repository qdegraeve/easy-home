import { Controller } from "@hotwired/stimulus"

// Choosing a photo with a French button instead of the browser's file field ("Choose file", in English). The button
// opens the camera or the gallery (the file input, hidden).
// - In the photos of a plant (send: true, the default), the chosen photo is sent at once: one gesture (UX review #35).
//   The button is then disabled, so that a second tap during a long upload does not send a second photo.
// - In a form (send: false), the name of the chosen file shows next to the button, and the form is sent as usual.
export default class extends Controller {
  static targets = ["input", "name", "button"]
  static values = { send: { type: Boolean, default: true } }

  choose(event) {
    event.preventDefault()
    this.inputTarget.click()
  }

  chosen() {
    const file = this.inputTarget.files[0]
    if (this.hasNameTarget) this.nameTarget.textContent = file ? file.name : ""
    if (!file || !this.sendValue) return

    this.buttonTargets.forEach((button) => { button.disabled = true })
    this.element.requestSubmit()
  }
}