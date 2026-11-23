import { Application } from "@hotwired/stimulus"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"
import AutosaveController from "../../app/javascript/controllers/autosave_controller"

describe("autosave controller", () => {
  let application

  const mount = async () => {
    document.body.innerHTML = `
      <form data-controller="autosave" data-action="change->autosave#save turbo:submit-end->autosave#sent">
        <input type="checkbox">
        <button type="submit" data-autosave-target="submit">Enregistrer</button>
      </form>`
    application = Application.start()
    application.register("autosave", AutosaveController)
    await Promise.resolve()
  }

  const form = () => document.querySelector("form")
  const change = () => document.querySelector("input").dispatchEvent(new Event("change", { bubbles: true }))
  const ended = (success = true) => form().dispatchEvent(new CustomEvent("turbo:submit-end", { detail: { success } }))

  beforeEach(() => vi.useFakeTimers())
  afterEach(() => {
    application.stop()
    vi.useRealTimers()
    vi.unstubAllGlobals()
  })

  it("hides the button and sends the form on each change", async () => {
    await mount()
    const submit = vi.spyOn(form(), "requestSubmit").mockImplementation(() => {})

    expect(document.querySelector("button").hidden).toBe(true)
    change()
    expect(submit).toHaveBeenCalledTimes(1)
  })

  it("sends a change made during a request once it ends, only once", async () => {
    await mount()
    const submit = vi.spyOn(form(), "requestSubmit").mockImplementation(() => {})

    change()
    change()
    change()
    expect(submit).toHaveBeenCalledTimes(1)

    ended()
    vi.runAllTimers()
    expect(submit).toHaveBeenCalledTimes(2)
    expect(form().hasAttribute("data-autosave-pending")).toBe(true)
    ended()
    expect(submit).toHaveBeenCalledTimes(2)
    expect(form().hasAttribute("data-autosave-pending")).toBe(false)
  })

  it("keeps the form marked unsaved and shows the button again when the request fails", async () => {
    await mount()
    vi.spyOn(form(), "requestSubmit").mockImplementation(() => {})

    change()
    ended(false)

    expect(form().hasAttribute("data-autosave-pending")).toBe(true)
    expect(document.querySelector("button").hidden).toBe(false)
  })

  it("sends a change still waiting when the page is left", async () => {
    await mount()
    vi.spyOn(form(), "requestSubmit").mockImplementation(() => {})
    const fetch = vi.fn(() => Promise.resolve())
    vi.stubGlobal("fetch", fetch)

    change()
    change()
    document.body.innerHTML = ""
    await Promise.resolve()

    expect(fetch).toHaveBeenCalledTimes(1)
    expect(fetch.mock.calls[0][1]).toMatchObject({ method: "POST", keepalive: true })
  })
})