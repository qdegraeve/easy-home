// In-page confirmation for data-turbo-confirm forms, instead of window.confirm: some webviews (the browser built
// into the Claude desktop app, Android webviews) never show it and always answer "no".
// The confirm button says what the action does (`button`, from data-confirm-button on the form) and turns red for a
// destructive action (`danger`, from data-confirm-tone="danger").
export function confirmWithDialog(message, { button, danger = false } = {}, root = document) {
  const dialog = root.getElementById("confirm-dialog")
  if (!dialog) return Promise.resolve(window.confirm(message))

  dialog.querySelector("[data-confirm-message]").textContent = message
  const confirmButton = dialog.querySelector("button[value=confirm]")
  confirmButton.textContent = button || confirmButton.dataset.defaultLabel
  confirmButton.dataset.tone = danger ? "danger" : ""
  dialog.returnValue = ""
  dialog.showModal()

  return new Promise((resolve) => {
    dialog.addEventListener("close", () => resolve(dialog.returnValue === "confirm"), { once: true })
  })
}

// Options for confirmWithDialog read from the submitted form.
export function confirmOptions(form) {
  return { button: form?.dataset.confirmButton, danger: form?.dataset.confirmTone === "danger" }
}