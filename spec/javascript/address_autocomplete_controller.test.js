import { Application } from "@hotwired/stimulus"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"
import AddressAutocompleteController from "../../app/javascript/controllers/address_autocomplete_controller"

const html = `
  <form data-controller="address-autocomplete" data-address-autocomplete-url-value="/address_suggestions"
        data-address-autocomplete-delay-value="100">
    <input data-address-autocomplete-target="input" data-action="input->address-autocomplete#search">
    <div data-address-autocomplete-target="results"></div>
    <input type="hidden" data-address-autocomplete-target="latitude" value="-20.1">
    <input type="hidden" data-address-autocomplete-target="longitude" value="55.1">
    <input data-address-autocomplete-target="altitude" value="320">
  </form>
`

const suggestion = `
  <button type="button" data-action="address-autocomplete#select"
          data-label="12 Rue des Exemples" data-latitude="-20.9" data-longitude="55.45">12 Rue des Exemples</button>
`

let application

const el = (target) => document.querySelector(`[data-address-autocomplete-target="${target}"]`)

const type = (value) => {
  el("input").value = value
  el("input").dispatchEvent(new Event("input"))
}

describe("address-autocomplete", () => {
  beforeEach(async () => {
    vi.useFakeTimers()
    globalThis.fetch = vi.fn(async () => ({ ok: true, text: async () => suggestion }))
    document.body.innerHTML = html
    application = Application.start()
    application.register("address-autocomplete", AddressAutocompleteController)
    await vi.waitFor(() => expect(application.controllers).toHaveLength(1))
  })

  afterEach(() => {
    application.stop()
    vi.useRealTimers()
  })

  it("clears the known position as soon as the address is retyped", () => {
    type("12")

    expect(el("latitude").value).toBe("")
    expect(el("longitude").value).toBe("")
    expect(el("altitude").value).toBe("")
  })

  it("does not query the server under three characters", async () => {
    type("12")
    await vi.runAllTimersAsync()

    expect(fetch).not.toHaveBeenCalled()
  })

  it("waits for typing to stop before querying the server, once", async () => {
    type("12 r")
    type("12 ru")
    type("12 rue")
    await vi.runAllTimersAsync()

    expect(fetch).toHaveBeenCalledTimes(1)
    expect(fetch.mock.calls[0][0].toString()).toContain("q=12+rue")
    expect(el("results").innerHTML).toContain("12 Rue des Exemples")
  })

  it("ignores a response arriving after a new keystroke", async () => {
    let resolveFirst
    fetch.mockImplementationOnce(() => new Promise((resolve) => (resolveFirst = resolve)))

    type("12 rue")
    await vi.advanceTimersByTimeAsync(100)
    el("input").value = "12 rue des"
    resolveFirst({ ok: true, text: async () => "<p>périmé</p>" })
    await vi.runAllTimersAsync()

    expect(el("results").innerHTML).not.toContain("périmé")
  })

  it("shows nothing when the server rejects the request (expired session)", async () => {
    fetch.mockResolvedValueOnce({ ok: false, status: 401, text: async () => "<h1>Connexion</h1>" })

    type("12 rue")
    await vi.runAllTimersAsync()

    expect(el("results").innerHTML).toBe("")
  })

  it("stays silent when offline", async () => {
    fetch.mockRejectedValueOnce(new TypeError("Failed to fetch"))

    type("12 rue")
    await vi.runAllTimersAsync()

    expect(el("results").innerHTML).toBe("")
  })

  it("fills the address and position when a suggestion is picked", async () => {
    type("12 rue")
    await vi.runAllTimersAsync()

    el("results").querySelector("button").click()

    expect(el("input").value).toBe("12 Rue des Exemples")
    expect(el("latitude").value).toBe("-20.9")
    expect(el("longitude").value).toBe("55.45")
    expect(el("results").innerHTML).toBe("")
  })
})