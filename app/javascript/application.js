// Entry point for the build script in your package.json
import { Turbo } from "@hotwired/turbo-rails"
import "./controllers"
import { confirmWithDialog, confirmOptions } from "./lib/confirm_dialog"

Turbo.config.forms.confirm = (message, form) => confirmWithDialog(message, confirmOptions(form))

// A morph refresh (home page after a completion, plant page) would fold the <details> the user opened ("Bientôt",
// archived plants): their state is the user's, not the server's.
document.addEventListener("turbo:before-morph-attribute", (event) => {
  if (event.target.tagName === "DETAILS" && event.detail.attributeName === "open") event.preventDefault()
})