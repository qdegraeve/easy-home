import { Application } from "@hotwired/stimulus"
import { afterEach, describe, expect, it, vi } from "vitest"
import PhotoPickerController from "../../app/javascript/controllers/photo_picker_controller"

describe("photo picker controller", () => {
  let application

  const mount = async (send = true) => {
    document.body.innerHTML = `
      <form data-controller="photo-picker" data-photo-picker-send-value="${send}">
        <input type="file" data-photo-picker-target="input" data-action="photo-picker#chosen">
        <button type="button" data-photo-picker-target="button" data-action="photo-picker#choose">Photo</button>
        <span data-photo-picker-target="name"></span>
      </form>`
    application = Application.start()
    application.register("photo-picker", PhotoPickerController)
    await Promise.resolve()
  }

  const form = () => document.querySelector("form")
  const input = () => document.querySelector("input")
  const button = () => document.querySelector("button")

  const choose = (file) => {
    Object.defineProperty(input(), "files", { value: file ? [file] : [], configurable: true })
    input().dispatchEvent(new Event("input")) // the default event of an input for Stimulus
  }

  afterEach(() => application.stop())

  it("opens the file chooser from the button", async () => {
    await mount()
    const opened = vi.fn()
    input().addEventListener("click", opened)

    button().click()
    expect(opened).toHaveBeenCalledOnce()
  })

  it("sends the chosen photo at once, and disables the button against a second send", async () => {
    await mount()
    form().requestSubmit = vi.fn()

    choose(new File(["x"], "ficus.jpg", { type: "image/jpeg" }))
    expect(form().requestSubmit).toHaveBeenCalledOnce()
    expect(button().disabled).toBe(true)
  })

  it("sends nothing when the chooser is closed without a photo", async () => {
    await mount()
    form().requestSubmit = vi.fn()

    choose(null)
    expect(form().requestSubmit).not.toHaveBeenCalled()
    expect(button().disabled).toBe(false)
  })

  it("in a form, shows the name of the chosen file and leaves the sending to the form", async () => {
    await mount(false)
    form().requestSubmit = vi.fn()

    choose(new File(["x"], "ficus.jpg", { type: "image/jpeg" }))
    expect(document.querySelector("span").textContent).toBe("ficus.jpg")
    expect(form().requestSubmit).not.toHaveBeenCalled()
  })
})