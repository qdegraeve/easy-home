import { Application } from "@hotwired/stimulus"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"
import ToastController from "../../app/javascript/controllers/toast_controller"

describe("toast controller", () => {
  let application

  const mount = async (html) => {
    document.body.innerHTML = `<div id="announcer" aria-live="polite"></div>${html}`
    application = Application.start()
    application.register("toast", ToastController)
    await Promise.resolve()
  }

  const announcer = () => document.getElementById("announcer")

  beforeEach(() => vi.useFakeTimers())

  afterEach(() => {
    application.stop()
    vi.useRealTimers()
  })

  it("lets a confirmation go away by itself after its duration, and announces it politely", async () => {
    await mount(`<div data-controller="toast" data-toast-duration-value="5000">Noté</div>`)

    vi.advanceTimersByTime(100)
    expect(announcer().textContent).toBe("Noté")
    expect(announcer().getAttribute("aria-live")).toBe("polite")

    vi.advanceTimersByTime(4899)
    expect(document.querySelector("[data-controller=toast]")).not.toBeNull()
    vi.advanceTimersByTime(1)
    expect(document.querySelector("[data-controller=toast]")).toBeNull()
  })

  it("waits while it has the focus, then counts again from the beginning", async () => {
    await mount(`<div data-controller="toast" data-toast-duration-value="5000">Noté<button>Annuler</button></div>`)
    const toast = document.querySelector("[data-controller=toast]")

    vi.advanceTimersByTime(4000)
    toast.dispatchEvent(new FocusEvent("focusin", { bubbles: true }))
    vi.advanceTimersByTime(60_000)
    expect(document.querySelector("[data-controller=toast]")).not.toBeNull()

    toast.dispatchEvent(new FocusEvent("focusout", { bubbles: true }))
    vi.advanceTimersByTime(4999)
    expect(document.querySelector("[data-controller=toast]")).not.toBeNull()
    vi.advanceTimersByTime(1)
    expect(document.querySelector("[data-controller=toast]")).toBeNull()
  })

  it("keeps an error until it is closed, and announces only its message, assertively", async () => {
    await mount(`
      <div data-controller="toast" data-toast-assertive-value="true">
        <span data-toast-target="message">Erreur</span><button data-action="toast#close">Fermer</button>
      </div>`)

    vi.advanceTimersByTime(60_000)
    expect(announcer().textContent).toBe("Erreur")
    expect(announcer().getAttribute("aria-live")).toBe("assertive")
    expect(document.querySelector("[data-controller=toast]")).not.toBeNull()

    document.querySelector("button").click()
    expect(document.querySelector("[data-controller=toast]")).toBeNull()
    expect(announcer().textContent).toBe("")
  })

  it("stops its timers when it leaves the page early, without failing later", async () => {
    await mount(`<div data-controller="toast" data-toast-duration-value="5000">Noté</div>`)

    document.querySelector("[data-controller=toast]").remove()
    await Promise.resolve()

    expect(() => vi.advanceTimersByTime(10_000)).not.toThrow()
    expect(announcer().textContent).toBe("")
  })

  it("takes its message out of the live region when it leaves the page", async () => {
    await mount(`<div data-controller="toast" data-toast-duration-value="5000">Noté</div>`)
    vi.advanceTimersByTime(200)
    expect(announcer().textContent).toBe("Noté")

    document.querySelector("[data-controller=toast]").remove()
    await Promise.resolve()

    expect(announcer().textContent).toBe("")
  })
})