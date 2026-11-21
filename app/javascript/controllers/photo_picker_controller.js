import { Controller } from "@hotwired/stimulus"

// Adding a photo in one gesture (UX review #35): the button opens the camera or the gallery (the file input, hidden),
// and the chosen photo is sent at once. Replaces the browser's file field ("Choose file", in English) and its
// separate send button.
export default class extends Controller {
  static targets = ["input"]

  choose(event) {
    event.preventDefault()
    this.inputTarget.click()
  }

  send() {
    if (this.inputTarget.files.length > 0) this.element.requestSubmit()
  }
}