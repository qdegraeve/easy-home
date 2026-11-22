import { Application } from "@hotwired/stimulus"
import { afterEach, beforeAll, beforeEach, describe, expect, it, vi } from "vitest"

let ButtonController, MenuController

// A fake Android app on the other side of the bridge: it records the messages and can answer them.
const app = {
  platform: "android",
  supportedComponents: ["button", "menu"],
  messages: [],
  supportsComponent(component) { return this.supportedComponents.includes(component) },
  receive(message) { this.messages.push(message) },
  reply(message, data = {}) { window.HotwireNative.web.receive({ ...message, data }) }
}

describe("bridge components", () => {
  let application

  beforeAll(async () => {
    // The app announces its components in its user agent (Hotwire Native), read when the library loads: the
    // controllers load only then. Hence the imports after setting it.
    Object.defineProperty(window.navigator, "userAgent", {
      value: "Mozilla/5.0 Hotwire Native Android; bridge-components: [button menu]",
      configurable: true
    })
    ButtonController = (await import("../../app/javascript/controllers/bridge/button_controller")).default
    MenuController = (await import("../../app/javascript/controllers/bridge/menu_controller")).default
    window.HotwireNative.web.setAdapter(app)
  })

  beforeEach(() => { app.messages = [] })

  afterEach(() => application?.stop())

  const mount = async (html) => {
    document.body.innerHTML = html
    application = Application.start()
    application.register("bridge--button", ButtonController)
    application.register("bridge--menu", MenuController)
    await new Promise((resolve) => setTimeout(resolve, 0))
  }

  it("asks the app for the floating button, and clicks the element when it is tapped", async () => {
    await mount(`<a href="#added" data-controller="bridge--button" data-bridge-title="Ajouter une plante"
                    data-bridge-icon="plus">Ajouter une plante</a>`)
    const click = vi.fn((event) => event.preventDefault())
    document.querySelector("a").addEventListener("click", click)

    const [message] = app.messages
    expect(message).toMatchObject({ component: "button", event: "connect",
                                    data: { title: "Ajouter une plante", icon: "plus" } })

    app.reply(message)
    expect(click).toHaveBeenCalledOnce()
  })

  it("sends the label and the order of a second button, then drops it when it leaves the page", async () => {
    await mount(`<a href="#analysis" data-controller="bridge--button" data-bridge-title="Nouvelle analyse"
                    data-bridge-label="Analyse" data-bridge-icon="analysis" data-bridge-order="2">Analyse</a>`)

    expect(app.messages[0].data).toMatchObject({ title: "Nouvelle analyse", label: "Analyse", icon: "analysis", order: 2,
                                           key: "Nouvelle analyse" })

    document.querySelector("a").remove()
    await new Promise((resolve) => setTimeout(resolve, 0))
    expect(app.messages.at(-1)).toMatchObject({ component: "button", event: "disconnect",
                                                data: { key: "Nouvelle analyse" } })
  })

  it("lists the actions in the app's menu, and clicks the chosen one", async () => {
    await mount(`
      <div data-controller="bridge--menu">
        <a href="#edit" data-bridge--menu-target="item">Modifier</a>
        <button data-bridge--menu-target="item">Supprimer</button>
      </div>`)
    const deleted = vi.fn()
    document.querySelector("button").addEventListener("click", deleted)

    const [message] = app.messages
    expect(message.data.items).toEqual([{ title: "Modifier", index: 0 }, { title: "Supprimer", index: 1 }])

    app.reply(message, { selectedIndex: 1 })
    expect(deleted).toHaveBeenCalledOnce()
  })

  it("sends the menu again when its actions change (a morph swaps them), with the new titles", async () => {
    await mount(`
      <div data-controller="bridge--menu">
        <button data-bridge--menu-target="item">Archiver</button>
      </div>`)
    document.querySelector("button").outerHTML = `<button data-bridge--menu-target="item">Restaurer</button>`
    await new Promise((resolve) => setTimeout(resolve, 0))

    const last = app.messages.filter((message) => message.component === "menu").at(-1)
    expect(last.data.items).toEqual([{ title: "Restaurer", index: 0 }])
  })

  it("marks the page with the components the app supports, to hide their web elements", () => {
    expect(document.documentElement.dataset.bridgeComponents).toBe("button menu")
  })
})