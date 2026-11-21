import { describe, it, expect, beforeEach, vi } from "vitest"
import { confirmWithDialog, confirmOptions } from "../../app/javascript/lib/confirm_dialog"

describe("confirmWithDialog", () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <dialog id="confirm-dialog">
        <form method="dialog">
          <p data-confirm-message></p>
          <button value="cancel">Non</button>
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
    expect(confirmOptions(form)).toEqual({ button: undefined, danger: false })

    form.dataset.confirmButton = "Supprimer"
    form.dataset.confirmTone = "danger"
    expect(confirmOptions(form)).toEqual({ button: "Supprimer", danger: true })
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

  it("falls back to window.confirm without an in-page dialog", async () => {
    document.body.innerHTML = ""
    const confirm = vi.fn(() => true)
    vi.stubGlobal("confirm", confirm)

    await expect(confirmWithDialog("Supprimer ?")).resolves.toBe(true)
    expect(confirm).toHaveBeenCalledWith("Supprimer ?")
    vi.unstubAllGlobals()
  })
})
