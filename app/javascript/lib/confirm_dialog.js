// In-page confirmation for data-turbo-confirm forms, instead of window.confirm: some webviews (the browser built
// into the Claude desktop app, Android webviews) never show it and always answer "no".
export function confirmWithDialog(message, root = document) {
  const dialog = root.getElementById("confirm-dialog")
  if (!dialog) return Promise.resolve(window.confirm(message))

  dialog.querySelector("[data-confirm-message]").textContent = message
  dialog.returnValue = ""
  dialog.showModal()

  return new Promise((resolve) => {
    dialog.addEventListener("close", () => resolve(dialog.returnValue === "confirm"), { once: true })
  })
}
