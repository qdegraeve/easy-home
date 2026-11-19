import { Controller } from "@hotwired/stimulus"

// Address autocomplete: queries the server while typing, then fills in the chosen position.
export default class extends Controller {
  static targets = ["input", "results", "latitude", "longitude", "altitude"]
  static values = { url: String, delay: { type: Number, default: 250 }, minLength: { type: Number, default: 3 } }

  disconnect() {
    clearTimeout(this.timeout)
  }

  search() {
    // A retyped address has no known position anymore: the altitude is recomputed on the next choice.
    this.latitudeTarget.value = ""
    this.longitudeTarget.value = ""
    this.altitudeTarget.value = ""
    clearTimeout(this.timeout)

    const query = this.inputTarget.value.trim()
    if (query.length < this.minLengthValue) {
      this.resultsTarget.innerHTML = ""
      return
    }

    this.timeout = setTimeout(() => this.#fetchSuggestions(query), this.delayValue)
  }

  select(event) {
    const { label, latitude, longitude } = event.currentTarget.dataset
    this.inputTarget.value = label
    this.latitudeTarget.value = latitude
    this.longitudeTarget.value = longitude
    this.resultsTarget.innerHTML = ""
  }

  async #fetchSuggestions(query) {
    const url = new URL(this.urlValue, window.location.origin)
    url.searchParams.set("q", query)

    try {
      const response = await fetch(url, { headers: { Accept: "text/html" } })
      // An error (expired session: 401) or a response arriving after a new keystroke is ignored.
      if (!response.ok || query !== this.inputTarget.value.trim()) return

      this.resultsTarget.innerHTML = await response.text()
    } catch {
      // Offline: no suggestion, the address can still be typed by hand.
    }
  }
}