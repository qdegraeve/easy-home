import { describe, it, expect, beforeEach, vi } from "vitest"
import { confirmWithDialog } from "../../app/javascript/lib/confirm_dialog"

describe("confirmWithDialog", () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <dialog id="confirm-dialog">
        <form method="dialog">
          <p data-confirm-message></p>
          <button value="cancel">Non</button>
          <button value="confirm">Oui</button>
        </form>
      </dialog>`
  })

  const dialog = () => document.getElementById("confirm-dialog")

  it("affiche le message dans la page et répond oui quand on confirme", async () => {
    const answer = confirmWithDialog("Supprimer ?")

    expect(dialog().open).toBe(true)
    expect(dialog().querySelector("[data-confirm-message]").textContent).toBe("Supprimer ?")
    dialog().close("confirm")

    await expect(answer).resolves.toBe(true)
  })

  it("répond non quand on revient en arrière ou qu'on ferme (Échap)", async () => {
    const cancelled = confirmWithDialog("Supprimer ?")
    dialog().close("cancel")
    await expect(cancelled).resolves.toBe(false)

    const escaped = confirmWithDialog("Supprimer ?")
    dialog().close()
    await expect(escaped).resolves.toBe(false)
  })

  it("ne réutilise pas la réponse précédente", async () => {
    const first = confirmWithDialog("A ?")
    dialog().close("confirm")
    await first

    const second = confirmWithDialog("B ?")
    dialog().close()
    await expect(second).resolves.toBe(false)
  })

  it("se rabat sur window.confirm sans boîte de dialogue dans la page", async () => {
    document.body.innerHTML = ""
    const confirm = vi.fn(() => true)
    vi.stubGlobal("confirm", confirm)

    await expect(confirmWithDialog("Supprimer ?")).resolves.toBe(true)
    expect(confirm).toHaveBeenCalledWith("Supprimer ?")
    vi.unstubAllGlobals()
  })
})
