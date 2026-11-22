import { Application } from "@hotwired/stimulus"
import { afterEach, describe, expect, it, vi } from "vitest"
import PhotoViewerController from "../../app/javascript/controllers/photo_viewer_controller"

describe("photo viewer controller", () => {
  const WIDTH = 400
  let application, strip

  const slide = (n, cover = false) => `
    <li data-photo-viewer-target="slide" data-url="/photos/${n}" data-title="Photo ${n}" data-position="${n} / 3"
        data-cover="${cover}">
      <template data-photo-viewer-target="actions"><button>Actions ${n}</button></template>
    </li>`

  const mount = async (index = 0) => {
    document.body.innerHTML = `
      <div data-controller="photo-viewer" data-photo-viewer-index-value="${index}"
           data-action="keydown@window->photo-viewer#key">
        <ul data-photo-viewer-target="strip">${slide(1)}${slide(2, true)}${slide(3)}</ul>
        <a href="/photos/0" data-photo-viewer-target="older" data-action="photo-viewer#older">‹</a>
        <h1 data-photo-viewer-target="title">Photo ${index + 1}</h1>
        <span data-photo-viewer-target="position"></span>
        <span data-photo-viewer-target="cover" hidden>Couverture</span>
        <a href="/photos/2" data-photo-viewer-target="newer" data-action="photo-viewer#newer">›</a>
        <div data-photo-viewer-target="menu"><button>Actions ${index + 1}</button></div>
        <input>
      </div>`
    strip = document.querySelector("ul")
    Object.defineProperty(strip, "clientWidth", { value: WIDTH, configurable: true })
    strip.scrollTo = vi.fn()
    application = Application.start()
    application.register("photo-viewer", PhotoViewerController)
    await Promise.resolve()
  }

  const controller = () => application.getControllerForElementAndIdentifier(
    document.querySelector("[data-controller]"), "photo-viewer"
  )
  const stopAt = (index) => {
    strip.scrollLeft = index * WIDTH
    controller().settle()
  }
  const press = (key, options = {}) => window.dispatchEvent(new KeyboardEvent("keydown", { key, ...options }))
  const older = () => document.querySelector("[data-photo-viewer-target=older]")
  const newer = () => document.querySelector("[data-photo-viewer-target=newer]")

  afterEach(() => application.stop())

  it("opens on the photo of the page", async () => {
    await mount(1)
    expect(strip.scrollLeft).toBe(WIDTH)
  })

  it("follows the photo the strip stops on: date, position, cover, arrows, actions and address", async () => {
    await mount(0)
    const replaceState = vi.spyOn(window.history, "replaceState")

    stopAt(1)
    expect(document.querySelector("h1").textContent).toBe("Photo 2")
    expect(document.querySelector("[data-photo-viewer-target=position]").textContent).toBe("2 / 3")
    expect(document.querySelector("[data-photo-viewer-target=cover]").hidden).toBe(false)
    expect(older().getAttribute("href")).toBe("/photos/1")
    expect(newer().getAttribute("href")).toBe("/photos/3")
    expect(document.querySelector("[data-photo-viewer-target=menu]").textContent).toBe("Actions 2")
    expect(replaceState).toHaveBeenLastCalledWith(window.history.state, "", "/photos/2")

    stopAt(2)
    expect(document.querySelector("[data-photo-viewer-target=cover]").hidden).toBe(true)
    expect(newer().getAttribute("aria-disabled")).toBe("true")
    expect(older().hasAttribute("aria-disabled")).toBe(false)
    replaceState.mockRestore()
  })

  it("waits for the strip to stop while it scrolls", async () => {
    vi.useFakeTimers()
    await mount(0)
    strip.scrollLeft = WIDTH
    controller().scrolled()
    expect(document.querySelector("h1").textContent).toBe("Photo 1")

    vi.advanceTimersByTime(200)
    expect(document.querySelector("h1").textContent).toBe("Photo 2")
    vi.useRealTimers()
  })

  it("scrolls to the next photo with the arrows, instead of loading its page", async () => {
    await mount(1)
    const click = new MouseEvent("click", { bubbles: true, cancelable: true })

    newer().dispatchEvent(click)
    expect(click.defaultPrevented).toBe(true)
    expect(strip.scrollTo).toHaveBeenLastCalledWith({ left: 2 * WIDTH, behavior: "smooth" })

    older().click()
    expect(strip.scrollTo).toHaveBeenLastCalledWith({ left: 0, behavior: "smooth" })
  })

  it("follows the arrow keys, except at the ends, in a field, in a dialog or with a modifier", async () => {
    await mount(0)

    press("ArrowLeft") // already the oldest
    expect(strip.scrollTo).not.toHaveBeenCalled()
    press("ArrowRight")
    expect(strip.scrollTo).toHaveBeenCalledOnce()

    press("ArrowRight", { metaKey: true })
    document.querySelector("input").dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowRight", bubbles: true }))
    document.body.insertAdjacentHTML("beforeend", "<dialog open></dialog>")
    press("ArrowRight")
    expect(strip.scrollTo).toHaveBeenCalledOnce()
  })
})