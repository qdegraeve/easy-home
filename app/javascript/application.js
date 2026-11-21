// Entry point for the build script in your package.json
import { Turbo } from "@hotwired/turbo-rails"
import "./controllers"
import { confirmWithDialog, confirmOptions } from "./lib/confirm_dialog"

Turbo.config.forms.confirm = (message, form) => confirmWithDialog(message, confirmOptions(form))