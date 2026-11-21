import { Application } from "@hotwired/stimulus"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"
import ToastController from "../../app/javascript/controllers/toast_controller"

describe("toast controller", () => {
  let application

  const mount = async (html) => {
    document.body.innerHTML = html
    application = Application.start()
    application.register("toast", ToastController)
    await Promise.resolve()
  }

  beforeEach(() => vi.useFakeTimers())

  afterEach(() => {
    application.stop()
    vi.useRealTimers()
  })

  it("lets a confirmation go away by itself after its duration", async () => {
    await mount(`<div data-controller="toast" data-toast-duration-value="5000">Noté</div>`)

    vi.advanceTimersByTime(4999)
    expect(document.body.textContent).toContain("Noté")
    vi.advanceTimersByTime(1)
    expect(document.body.textContent).not.toContain("Noté")
  })

  it("keeps an error until it is closed", async () => {
    await mount(`
      <div data-controller="toast">Erreur<button data-action="toast#close">Fermer</button></div>`)

    vi.advanceTimersByTime(60_000)
    expect(document.body.textContent).toContain("Erreur")
    document.querySelector("button").click()
    expect(document.body.textContent).not.toContain("Erreur")
  })
})