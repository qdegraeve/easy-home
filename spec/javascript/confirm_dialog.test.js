import { describe, it, expect, beforeEach, vi } from "vitest"
import { confirmWithDialog, confirmOptions } from "../../app/javascript/lib/confirm_dialog"

describe("confirmWithDialog", () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <dialog id="confirm-dialog">
        <form method="dialog">
          <p data-confirm-message></p>
          <button value="cancel" data-default-label="Revenir">Revenir</button>
          <button value="confirm" data-default-label="Confirmer">Confirmer</button>
        </form>
      </dialog>`
  })

  const dialog = () => document.getElementById("confirm-dialog")

  it("shows the message in the page and answers yes on confirm", async () => {
    const answer = confirmWithDialog("Supprimer ?")

    expect(dialog().open).toBe(true)
    expect(dialog().querySelector("[data-confirm-message]").textContent).toBe("Supprimer ?")
    dialog().close("confirm")

    await expect(answer).resolves.toBe(true)
  })

  it("names the confirm button after the action, in red when destructive, then resets it", async () => {
    const button = () => dialog().querySelector("button[value=confirm]")

    const deletion = confirmWithDialog("Supprimer la photo ?", { button: "Supprimer", danger: true })
    expect(button().textContent).toBe("Supprimer")
    expect(button().dataset.tone).toBe("danger")
    dialog().close("cancel")
    await deletion

    const other = confirmWithDialog("Archiver ?")
    expect(button().textContent).toBe("Confirmer")
    expect(button().dataset.tone).toBe("")
    dialog().close()
    await other
  })

  it("reads the options from the submitted form", () => {
    const form = document.createElement("form")
    expect(confirmOptions(form)).toEqual({ button: undefined, cancel: undefined, danger: false })

    form.dataset.confirmButton = "Supprimer"
    form.dataset.confirmCancel = "Garder"
    form.dataset.confirmTone = "danger"
    expect(confirmOptions(form)).toEqual({ button: "Supprimer", cancel: "Garder", danger: true })
  })

  it("names the cancel button after what is kept, then resets it", async () => {
    const cancel = () => dialog().querySelector("button[value=cancel]")

    const removal = confirmWithDialog("Retirer ?", { button: "Retirer", cancel: "Garder" })
    expect(cancel().textContent).toBe("Garder")
    dialog().close("cancel")
    await removal

    const other = confirmWithDialog("Archiver ?")
    expect(cancel().textContent).toBe("Revenir")
    dialog().close()
    await other
  })

  it("answers no on going back or closing (Escape)", async () => {
    const cancelled = confirmWithDialog("Supprimer ?")
    dialog().close("cancel")
    await expect(cancelled).resolves.toBe(false)

    const escaped = confirmWithDialog("Supprimer ?")
    dialog().close()
    await expect(escaped).resolves.toBe(false)
  })

  it("does not reuse the previous answer", async () => {
    const first = confirmWithDialog("A ?")
    dialog().close("confirm")
    await first

    const second = confirmWithDialog("B ?")
    dialog().close()
    await expect(second).resolves.toBe(false)
  })

  it("answers no to a confirmation left pending when another one starts", async () => {
    const first = confirmWithDialog("A ?")
    dialog().removeAttribute("open") // closed without a "close" event, as a page morph would
    const second = confirmWithDialog("B ?")

    await expect(first).resolves.toBe(false)
    dialog().close("confirm")
    await expect(second).resolves.toBe(true)
  })

  it("ignores a late close event of a previous opening", async () => {
    let answered = false
    const pending = confirmWithDialog("B ?").then((value) => { answered = true; return value })

    dialog().dispatchEvent(new Event("close")) // queued from an earlier close, delivered while reopened
    await Promise.resolve()
    expect(answered).toBe(false)

    dialog().close("confirm")
    await expect(pending).resolves.toBe(true)
  })

  it("falls back to window.confirm without an in-page dialog", async () => {
    document.body.innerHTML = ""
    const confirm = vi.fn(() => true)
    vi.stubGlobal("confirm", confirm)

    await expect(confirmWithDialog("Supprimer ?")).resolves.toBe(true)
    expect(confirm).toHaveBeenCalledWith("Supprimer ?")
    vi.unstubAllGlobals()
  })
})
