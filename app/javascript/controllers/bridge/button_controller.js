import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

// The main action of a page as the floating button of the Android app: "+" to add a plant. Tapping it clicks
// this element (a link or a button). In the browser, or with an app that does not know the component, the element
// stays where it is (see the CSS of application.tailwind.css).
//
//   <a href="/plants/new" data-controller="bridge--button" data-bridge-title="Ajouter une plante"
//      data-bridge-icon="plus">Ajouter une plante</a>
export default class extends BridgeComponent {
  static component = "button"

  connect() {
    super.connect()
    const title = this.bridgeElement.bridgeAttribute("title")
    const icon = this.bridgeElement.bridgeAttribute("icon")
    const label = this.bridgeElement.bridgeAttribute("label") // the word on the button: "Tâche"
    // order: the main button is the lowest (1 by default); key: the same button when it connects again (morph).
    const order = Number(this.bridgeElement.bridgeAttribute("order") || 1)
    this.key = title
    this.send("connect", { title, label, icon, order, key: title }, () => this.element.click())
  }

  // The element leaves the page (another tab, a refresh that no longer has it): the app drops its button.
  disconnect() {
    this.send("disconnect", { key: this.key })
    super.disconnect()
  }
}