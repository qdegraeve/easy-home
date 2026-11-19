// Confirmation des formulaires data-turbo-confirm dans la page, au lieu de window.confirm : certaines webviews (le
// navigateur intégré de l'app de bureau Claude, des webviews Android) ne l'affichent pas et répondent toujours « non ».
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
