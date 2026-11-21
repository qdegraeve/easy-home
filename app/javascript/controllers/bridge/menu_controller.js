import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

// The secondary actions of a page in the "⋮" menu of the native top bar (Android app): edit, archive, delete a
// plant. Choosing one clicks its element in the page, so that a confirmation still shows (the delete one). In the
// browser, the actions stay in the page.
//
//   <div data-controller="bridge--menu">
//     <a href="…" data-bridge--menu-target="item">Modifier</a>
//     <form …><button data-bridge--menu-target="item">Supprimer</button></form>
//   </div>
export default class extends BridgeComponent {
  static component = "menu"
  static targets = ["item"]

  connect() {
    super.connect()
    const items = this.itemTargets.map((item, index) => ({ title: item.textContent.trim(), index }))
    this.send("connect", { items }, (message) => this.itemTargets[message.data.selectedIndex]?.click())
  }
}