import { Controller } from "@hotwired/stimulus"

// "Copier": puts a text (the link of an invitation) in the clipboard and says so on the button for a moment.
//
//   <button data-controller="clipboard" data-clipboard-text-value="https://…" data-clipboard-done-value="Copié"
//           data-action="clipboard#copy">Copier</button>
export default class extends Controller {
  static values = { text: String, done: String }

  connect() {
    this.label = this.element.textContent
  }

  async copy() {
    await navigator.clipboard.writeText(this.textValue)
    this.element.textContent = this.doneValue
    clearTimeout(this.timer)
    this.timer = setTimeout(() => { this.element.textContent = this.label }, 2000)
  }

  disconnect() {
    clearTimeout(this.timer)
    this.element.textContent = this.label
  }
}
