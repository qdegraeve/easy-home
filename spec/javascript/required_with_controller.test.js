import { Application } from "@hotwired/stimulus"
import { afterEach, describe, expect, it } from "vitest"
import RequiredWithController from "../../app/javascript/controllers/required_with_controller"

describe("required with controller", () => {
  let application

  afterEach(() => application.stop())

  it("requires the fields while the source is filled, not when it is blank", async () => {
    document.body.innerHTML = `
      <div data-controller="required-with">
        <input type="text" data-required-with-target="source" data-action="required-with#update">
        <input type="radio" data-required-with-target="field">
      </div>`
    application = Application.start()
    application.register("required-with", RequiredWithController)
    await Promise.resolve()
    const source = document.querySelector("input[type=text]")
    const radio = document.querySelector("input[type=radio]")

    expect(radio.required).toBe(false)
    source.value = "Terrasse"
    source.dispatchEvent(new Event("input"))
    expect(radio.required).toBe(true)
    source.value = "  "
    source.dispatchEvent(new Event("input"))
    expect(radio.required).toBe(false)
  })
})