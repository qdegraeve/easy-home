import { Controller } from "@hotwired/stimulus"

// Fields required only once another one is filled: the exposure of a new place, as soon as its name is typed. The
// browser then asks for it before sending, rather than the server after, which would cost the chosen photo (a file
// field is never filled again).
export default class extends Controller {
  static targets = ["source", "field"]

  connect() {
    this.update()
  }

  update() {
    const filled = this.sourceTarget.value.trim() !== ""
    this.fieldTargets.forEach((field) => (field.required = filled))
  }
}