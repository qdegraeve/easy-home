import { Controller } from "@hotwired/stimulus"

// Autocomplétion d'adresse : interroge le serveur pendant la saisie, puis remplit la position choisie.
export default class extends Controller {
  static targets = ["input", "results", "latitude", "longitude", "altitude"]
  static values = { url: String, delay: { type: Number, default: 250 }, minLength: { type: Number, default: 3 } }

  disconnect() {
    clearTimeout(this.timeout)
  }

  search() {
    // Une adresse retapée à la main n'a plus de position connue : l'altitude sera recalculée au choix suivant.
    this.latitudeTarget.value = ""
    this.longitudeTarget.value = ""
    this.altitudeTarget.value = ""
    clearTimeout(this.timeout)

    const query = this.inputTarget.value.trim()
    if (query.length < this.minLengthValue) {
      this.resultsTarget.innerHTML = ""
      return
    }

    this.timeout = setTimeout(() => this.fetchSuggestions(query), this.delayValue)
  }

  select(event) {
    const { label, latitude, longitude } = event.currentTarget.dataset
    this.inputTarget.value = label
    this.latitudeTarget.value = latitude
    this.longitudeTarget.value = longitude
    this.resultsTarget.innerHTML = ""
  }

  async fetchSuggestions(query) {
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("q", query)

    const response = await fetch(url, { headers: { Accept: "text/html" } })
    // Une réponse arrivée après une nouvelle frappe est ignorée.
    if (!response.ok || query !== this.inputTarget.value.trim()) return

    this.resultsTarget.innerHTML = await response.text()
  }
}