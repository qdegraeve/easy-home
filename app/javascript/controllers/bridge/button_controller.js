import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

// The main action of a page as a button of the native top bar (Android app): "+" to add a plant. Tapping it clicks
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
    this.send("connect", { title, icon }, () => this.element.click())
  }
}