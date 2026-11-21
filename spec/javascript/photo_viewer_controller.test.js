import { Application } from "@hotwired/stimulus"
import { afterEach, describe, expect, it, vi } from "vitest"
import PhotoViewerController from "../../app/javascript/controllers/photo_viewer_controller"

describe("photo viewer controller", () => {
  let application, clicks

  const mount = async ({ older = true, newer = true, preload = [] } = {}) => {
    document.body.innerHTML = `
      <div data-controller="photo-viewer" data-photo-viewer-preload-value='${JSON.stringify(preload)}'
           data-action="keydown@window->photo-viewer#key">
        <div id="stage" data-action="pointerdown->photo-viewer#start pointermove->photo-viewer#move
                                     pointerup->photo-viewer#end pointercancel->photo-viewer#cancel">
          <img data-photo-viewer-target="image">
        </div>
        ${older ? `<a href="#older" data-photo-viewer-target="older" data-action="photo-viewer#mark">‹</a>` : ""}
        ${newer ? `<a href="#newer" data-photo-viewer-target="newer" data-action="photo-viewer#mark">›</a>` : ""}
        <input>
      </div>`
    clicks = []
    document.querySelectorAll("a").forEach((link) => link.addEventListener("click", (event) => {
      event.preventDefault()
      clicks.push(link.getAttribute("href"))
    }))
    application = Application.start()
    application.register("photo-viewer", PhotoViewerController)
    await Promise.resolve()
  }

  const stage = () => document.getElementById("stage")
  const image = () => document.querySelector("img")
  const pointer = (type, x, y, options = {}) => stage().dispatchEvent(new PointerEvent(type, {
    clientX: x, clientY: y, pointerType: "touch", isPrimary: true, bubbles: true, ...options
  }))
  const swipe = (dx, dy = 0, options = {}) => {
    pointer("pointerdown", 200, 200, options)
    pointer("pointermove", 200 + dx / 2, 200 + dy / 2, options)
    pointer("pointermove", 200 + dx, 200 + dy, options)
    pointer("pointerup", 200 + dx, 200 + dy, options)
  }
  const press = (key, options = {}) => window.dispatchEvent(new KeyboardEvent("keydown", { key, ...options }))

  afterEach(() => {
    application.stop()
    delete document.documentElement.dataset.photoDirection
    delete document.documentElement.dataset.photoInput
  })

  it("goes to the older photo on a swipe to the right, to the newer one on a swipe to the left", async () => {
    await mount()

    swipe(120)
    expect(clicks).toEqual(["#older"])
    expect(document.documentElement.dataset.photoDirection).toBe("older")

    swipe(-120)
    expect(clicks).toEqual(["#older", "#newer"])
    expect(document.documentElement.dataset.photoDirection).toBe("newer")
    expect(document.documentElement.dataset.photoInput).toBe("pointer")
  })

  it("lets the photo follow the finger, and puts it back below the threshold", async () => {
    await mount()

    pointer("pointerdown", 200, 200)
    pointer("pointermove", 240, 200)
    expect(image().style.transform).toBe("translateX(40px)")
    pointer("pointerup", 240, 200)

    expect(clicks).toEqual([])
    expect(image().style.transform).toBe("")
  })

  it("leaves a mostly vertical gesture to the page scroll", async () => {
    await mount()

    swipe(60, 200)
    expect(clicks).toEqual([])
    expect(image().style.transform).toBe("")
  })

  it("ignores the mouse, a second finger and a cancelled gesture", async () => {
    await mount()

    swipe(120, 0, { pointerType: "mouse" })
    swipe(120, 0, { isPrimary: false })
    pointer("pointerdown", 200, 200)
    pointer("pointermove", 320, 200)
    pointer("pointercancel", 320, 200)
    pointer("pointerup", 320, 200)

    expect(clicks).toEqual([])
    expect(image().style.transform).toBe("")
  })

  it("resists at the end of the photos and goes nowhere", async () => {
    await mount({ newer: false })

    pointer("pointerdown", 200, 200)
    pointer("pointermove", 100, 200)
    expect(image().style.transform).toBe("translateX(-30px)")
    pointer("pointerup", 100, 200)
    expect(clicks).toEqual([])
  })

  it("follows the arrow keys, except in a field, in a dialog or with a modifier", async () => {
    await mount()

    press("ArrowLeft")
    press("ArrowRight")
    expect(clicks).toEqual(["#older", "#newer"])
    expect(document.documentElement.dataset.photoInput).toBe("key")

    press("ArrowLeft", { metaKey: true })
    document.querySelector("input").dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowLeft", bubbles: true }))
    document.body.insertAdjacentHTML("beforeend", "<dialog open></dialog>")
    press("ArrowLeft")
    expect(clicks).toEqual(["#older", "#newer"])
  })

  it("preloads the neighbour photos", async () => {
    const images = []
    const RealImage = window.Image
    window.Image = class extends RealImage { constructor() { super(); images.push(this) } }

    await mount({ preload: ["/older.jpg", "/newer.jpg"] })
    window.Image = RealImage

    expect(images.map((preloaded) => new URL(preloaded.src).pathname)).toEqual(["/older.jpg", "/newer.jpg"])
  })

  it("after a keyboard move, gives the focus back to the link used, or to the other one at the end", async () => {
    document.documentElement.dataset.photoDirection = "older"
    document.documentElement.dataset.photoInput = "key"
    await mount()
    expect(document.activeElement.getAttribute("href")).toBe("#older")
    application.stop()

    document.documentElement.dataset.photoDirection = "older"
    document.documentElement.dataset.photoInput = "key"
    await mount({ older: false })
    expect(document.activeElement.getAttribute("href")).toBe("#newer")
    application.stop()

    // After a swipe, no focus ring on a phone.
    document.documentElement.dataset.photoDirection = "older"
    document.documentElement.dataset.photoInput = "pointer"
    await mount()
    expect(document.activeElement).toBe(document.body)
  })

  it("waits for the fresh page, not the cached preview, to give the focus back", async () => {
    document.documentElement.dataset.photoDirection = "older"
    document.documentElement.dataset.photoInput = "key"
    document.documentElement.setAttribute("data-turbo-preview", "")
    await mount()
    document.documentElement.removeAttribute("data-turbo-preview")

    expect(document.activeElement).toBe(document.body)
    expect(document.documentElement.dataset.photoInput).toBe("key")
  })

  it("forgets the direction on a deletion", async () => {
    await mount()
    document.documentElement.dataset.photoDirection = "older"

    application.getControllerForElementAndIdentifier(document.querySelector("[data-controller]"), "photo-viewer")
      .forgetDirection()
    expect(document.documentElement.dataset.photoDirection).toBeUndefined()
  })
})