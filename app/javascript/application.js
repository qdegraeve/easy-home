// Entry point for the build script in your package.json
import { Turbo } from "@hotwired/turbo-rails"
import "./controllers"
import { confirmWithDialog } from "./confirm_dialog"

Turbo.config.forms.confirm = (message) => confirmWithDialog(message)
