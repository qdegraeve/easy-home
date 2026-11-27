import { Application } from "@hotwired/stimulus"
import { afterEach, beforeAll, beforeEach, describe, expect, it, vi } from "vitest"

vi.mock("@hotwired/turbo-rails", () => ({ Turbo: { visit: vi.fn() } }))

let PushController, Turbo

// A fake Android app on the other side of the bridge: it records the messages and answers them.
const app = {
  platform: "android",
  supportedComponents: ["push"],
  messages: [],
  supportsComponent(component) { return this.supportedComponents.includes(component) },
  receive(message) { this.messages.push(message) },
  reply(message, data = {}) { window.HotwireNative.web.receive({ ...message, data }) }
}

const TOKEN = "firebase-token-of-this-phone"
const FINGERPRINT = "4e5ad2bc7fdd8cc6e6c33fcca1b1347a0dc8bf2fdd7d55e0a1f63a29c6e9b6a5" // not this token's

describe("push bridge component", () => {
  let application

  beforeAll(async () => {
    // Read by the bridge library when it loads: the controller is imported only then.
    Object.defineProperty(window.navigator, "userAgent", {
      value: "Mozilla/5.0 Hotwire Native Android; bridge-components: [push]",
      configurable: true
    })
    PushController = (await import("../../app/javascript/controllers/bridge/push_controller")).default
    Turbo = (await import("@hotwired/turbo-rails")).Turbo
    window.HotwireNative.web.setAdapter(app)
  })

  beforeEach(() => {
    app.messages = []
    Turbo.visit.mockClear()
    window.fetch = vi.fn(async () => ({ ok: true }))
  })

  // Whatever a test left running ends before the next one: a late request never lands in another test.
  afterEach(async () => {
    await controller()?.handling
    application?.stop()
  })

  const mount = async (fingerprints = []) => {
    document.head.innerHTML = `<meta name="csrf-token" content="csrf-123">`
    document.body.innerHTML = `
      <section data-controller="bridge--push" data-bridge--push-url-value="/push_devices"
               data-bridge--push-fingerprints-value='${JSON.stringify(fingerprints)}'>
        <button data-action="bridge--push#enable">Recevoir les notifications sur ce téléphone</button>
        <p data-bridge--push-target="denied" hidden>Bloquées</p>
        <p data-bridge--push-target="unavailable" hidden>Indisponibles</p>
      </section>`
    application = Application.start()
    application.register("bridge--push", PushController)
    await vi.waitFor(() => expect(message("token")).toBeDefined()) // connected: the app was asked
  }

  const controller = () => application?.controllers[0]
  // The app answers, then the test waits for the page to be done with the answer (hash, request): a state, not a
  // duration.
  const answer = async (event, data) => {
    app.reply(message(event), data)
    await controller().handling
  }
  const sha256 = async (text) => {
    const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text))
    return Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, "0")).join("")
  }
  const message = (event) => app.messages.find((sent) => sent.event === event)

  it("posts the token of the app when the session does not know it yet", async () => {
    await mount([ FINGERPRINT ])

    await answer("token", { status: "granted", token: TOKEN, name: "Pixel 9" })

    expect(window.fetch).toHaveBeenCalledOnce()
    const [url, request] = window.fetch.mock.calls[0]
    expect(url).toBe("/push_devices")
    expect(request.method).toBe("POST")
    expect(request.headers["X-CSRF-Token"]).toBe("csrf-123")
    expect(JSON.parse(request.body)).toEqual({ push_device: { token: TOKEN, name: "Pixel 9" } })
    expect(Turbo.visit).not.toHaveBeenCalled()
  })

  it("posts nothing when the session already knows the token, or when notifications are not allowed", async () => {
    await mount([ await sha256(TOKEN) ])
    await answer("token", { status: "granted", token: TOKEN })
    expect(window.fetch).not.toHaveBeenCalled()

    application.stop()
    app.messages = []
    await mount()
    await answer("token", { status: "prompt" })
    expect(window.fetch).not.toHaveBeenCalled()
  })

  it("asks the app for the permission, registers the phone, then reloads the page", async () => {
    await mount()
    document.querySelector("button").click()
    await vi.waitFor(() => expect(message("enable")).toBeDefined())

    await answer("enable", { status: "granted", token: TOKEN, name: "Pixel 9" })

    expect(window.fetch).toHaveBeenCalledOnce()
    expect(Turbo.visit).toHaveBeenCalledWith(window.location.href, { action: "replace" })
  })

  it("explains a refused permission and opens the phone's settings on demand", async () => {
    await mount()
    document.querySelector("button").click()
    await vi.waitFor(() => expect(message("enable")).toBeDefined())

    await answer("enable", { status: "denied" })

    expect(document.querySelector("[data-bridge--push-target=denied]").hidden).toBe(false)
    expect(document.querySelector("[data-bridge--push-target=unavailable]").hidden).toBe(true)
    expect(window.fetch).not.toHaveBeenCalled()
    expect(Turbo.visit).not.toHaveBeenCalled()

    controller().openSettings()
    expect(message("openSettings")).toBeDefined()
  })

  it("says when the app cannot receive notifications at all", async () => {
    await mount()
    document.querySelector("button").click()
    await vi.waitFor(() => expect(message("enable")).toBeDefined())

    await answer("enable", { status: "unavailable" })

    expect(document.querySelector("[data-bridge--push-target=unavailable]").hidden).toBe(false)
    expect(document.querySelector("[data-bridge--push-target=denied]").hidden).toBe(true)
  })

  it("leaves the session as it was when Rails refuses the token", async () => {
    window.fetch = vi.fn(async () => ({ ok: false }))
    await mount()
    document.querySelector("button").click()
    await vi.waitFor(() => expect(message("enable")).toBeDefined())

    await answer("enable", { status: "granted", token: TOKEN })

    expect(controller().fingerprintsValue).toEqual([])
  })
})