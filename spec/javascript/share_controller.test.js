import { Application } from "@hotwired/stimulus"
import { afterEach, describe, expect, it, vi } from "vitest"
import ShareController from "../../app/javascript/controllers/share_controller"

// "Partager": the app's share sheet through the bridge, else the browser's, else no button.
describe("share controller", () => {
  let application

  afterEach(() => {
    application?.stop()
    delete navigator.share
    delete document.documentElement.dataset.bridgeComponents
  })

  const mount = async () => {
    document.body.innerHTML = `
      <button data-controller="share" data-share-text-value="Rejoins Maison : https://x/i/abc"
              data-action="share#share">Partager</button>`
    application = Application.start()
    application.register("share", ShareController)
    await vi.waitFor(() => expect(application.controllers).toHaveLength(1))
    return document.querySelector("button")
  }

  it("hides the button without a share sheet: Copier stays", async () => {
    const button = await mount()

    expect(button.hidden).toBe(true)
  })

  it("opens the share sheet of the browser with the text", async () => {
    navigator.share = vi.fn(async () => {})
    const button = await mount()

    button.click()

    expect(button.hidden).toBe(false)
    expect(navigator.share).toHaveBeenCalledWith({ text: "Rejoins Maison : https://x/i/abc" })
  })

  it("asks the app when it supports sharing, never the browser", async () => {
    document.documentElement.dataset.bridgeComponents = "button menu share"
    navigator.share = vi.fn(async () => {})
    const button = await mount()
    const asked = vi.fn()
    button.addEventListener("share:native", (event) => asked(event.detail))

    button.click()

    expect(button.hidden).toBe(false)
    expect(asked).toHaveBeenCalledWith({ text: "Rejoins Maison : https://x/i/abc" })
    expect(navigator.share).not.toHaveBeenCalled()
  })
})
