// In-page confirmation for data-turbo-confirm forms, instead of window.confirm: some webviews (the browser built
// into the Claude desktop app, Android webviews) never show it and always answer "no".
// The confirm button says what the action does (`button`, from data-confirm-button on the form) and turns red for a
// destructive action (`danger`, from data-confirm-tone="danger"). The cancel button can say what is kept (`cancel`,
// from data-confirm-cancel), when "Revenir" would be unclear.
// A confirmation still pending when another one opens answers "no": a form is never submitted twice.
let pendingAnswer = null

export function confirmWithDialog(message, { button, cancel, danger = false } = {}, root = document) {
  const dialog = root.getElementById("confirm-dialog")
  if (!dialog) return Promise.resolve(window.confirm(message))

  pendingAnswer?.(false)
  if (dialog.open) dialog.close()

  dialog.querySelector("[data-confirm-message]").textContent = message
  const confirmButton = dialog.querySelector("button[value=confirm]")
  confirmButton.textContent = button || confirmButton.dataset.defaultLabel
  confirmButton.dataset.tone = danger ? "danger" : ""
  const cancelButton = dialog.querySelector("button[value=cancel]")
  if (cancelButton) cancelButton.textContent = cancel || cancelButton.dataset.defaultLabel || cancelButton.textContent
  dialog.returnValue = ""
  dialog.showModal()

  return new Promise((resolve) => {
    const answer = (value) => {
      if (pendingAnswer !== answer) return
      pendingAnswer = null
      resolve(value)
    }
    pendingAnswer = answer
    // The "close" event is queued: when the dialog was reopened meanwhile, it is not this answer.
    const onClose = () => {
      if (dialog.open) return
      dialog.removeEventListener("close", onClose)
      answer(dialog.returnValue === "confirm")
    }
    dialog.addEventListener("close", onClose)
  })
}

// Options for confirmWithDialog read from the submitted form.
export function confirmOptions(form) {
  return {
    button: form?.dataset.confirmButton,
    cancel: form?.dataset.confirmCancel,
    danger: form?.dataset.confirmTone === "danger"
  }
}