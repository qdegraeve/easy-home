import { Controller } from "@hotwired/stimulus"

// Photo viewer of a plant: its photos side by side in a strip snapped on each photo, the oldest on the left. The
// finger scrolls the strip natively (momentum, snap), the arrows and the arrow keys scroll it to the next photo. No
// page is loaded: in the Android app, the screen and its top bar stay. Once the strip stops, the page follows the
// photo shown: date, position, cover mark, arrows, actions ("⋮" menu in the app) and address (refresh, "back").
const SETTLE_DELAY = 120 // ms without scroll: stopped, where the scrollend event is missing

export default class extends Controller {
  static targets = ["strip", "slide", "actions", "title", "position", "cover", "older", "newer", "menu"]
  static values = { index: Number }

  connect() {
    this.current = this.indexValue
    this.stripTarget.scrollLeft = this.current * this.stripTarget.clientWidth // at once, before the first paint
  }

  disconnect() {
    clearTimeout(this.settleTimer)
  }

  older(event) {
    event.preventDefault()
    this.scrollTo(this.current - 1)
  }

  newer(event) {
    event.preventDefault()
    this.scrollTo(this.current + 1)
  }

  key(event) {
    if (event.defaultPrevented || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return
    if (event.target.closest?.("input, textarea, select, [contenteditable]")) return
    if (document.querySelector("dialog[open]")) return

    const step = { ArrowLeft: -1, ArrowRight: 1 }[event.key]
    if (!step) return

    event.preventDefault()
    this.scrollTo(this.current + step)
  }

  scrolled() {
    clearTimeout(this.settleTimer)
    this.settleTimer = setTimeout(() => this.settle(), SETTLE_DELAY)
  }

  // The strip stopped on a photo: the page shows what goes with it.
  settle() {
    clearTimeout(this.settleTimer)
    const width = this.stripTarget.clientWidth
    if (!width) return

    const index = Math.round(this.stripTarget.scrollLeft / width)
    if (index === this.current || !this.slideTargets[index]) return

    this.current = index
    this.show(this.slideTargets[index], index)
  }

  scrollTo(index) {
    if (index < 0 || index >= this.slideTargets.length) return

    const reduce = window.matchMedia?.("(prefers-reduced-motion: reduce)").matches
    this.stripTarget.scrollTo({ left: index * this.stripTarget.clientWidth, behavior: reduce ? "auto" : "smooth" })
  }

  show(slide, index) {
    const { title, position, cover, url } = slide.dataset
    this.titleTarget.textContent = title
    this.positionTarget.textContent = position
    this.coverTarget.hidden = cover !== "true"
    this.point(this.olderTarget, this.slideTargets[index - 1])
    this.point(this.newerTarget, this.slideTargets[index + 1])
    this.menuTarget.replaceChildren(this.actionsTargets[index].content.cloneNode(true))
    // Turbo keeps its state in the history entry: kept, only the address changes.
    window.history.replaceState(window.history.state, "", url)
  }

  // An arrow leads to the photo next to it, or is disabled (hidden) at the end of the strip.
  point(link, slide) {
    if (slide) {
      link.href = slide.dataset.url
      link.removeAttribute("aria-disabled")
    } else {
      link.setAttribute("aria-disabled", "true")
    }
  }
}