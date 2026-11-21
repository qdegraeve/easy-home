import { Controller } from "@hotwired/stimulus"

// Photo viewer of a plant: swipe and arrow keys between its photos. The photo follows the finger; past a threshold
// the older or newer link is clicked, so the visit is the same as a tap on it (a page per photo, replaced in the
// history: "back" leaves the photos). The links stay the way to do it without a gesture.
// - Swipe right: the older photo comes from the left (left is the past, as on a timeline). Swipe left: the newer one.
// - The direction is put on <html> for the slide of the view transition (application.tailwind.css).
const LOCK_DISTANCE = 10 // px before the gesture is known as horizontal or vertical
const MAX_THRESHOLD = 80 // px, or a fifth of the width on a small screen
const RESISTANCE = 0.3 // at the end of the photos, the photo only follows the finger a little

export default class extends Controller {
  static targets = ["image", "older", "newer"]
  static values = { preload: Array }

  connect() {
    // The neighbours in the browser cache: the next photo shows at once.
    this.preloaded = this.preloadValue.map((url) => Object.assign(new Image(), { decoding: "async", src: url }))
    this.restoreFocus()
  }

  start(event) {
    if (event.pointerType === "mouse" || !event.isPrimary) return this.cancel()

    Object.assign(this, { tracking: true, axis: null, dx: 0, x0: event.clientX, y0: event.clientY })
  }

  move(event) {
    if (!this.tracking || !event.isPrimary) return

    const dx = event.clientX - this.x0
    const dy = event.clientY - this.y0
    if (!this.axis && Math.hypot(dx, dy) > LOCK_DISTANCE) this.axis = Math.abs(dx) > Math.abs(dy) * 1.5 ? "x" : "y"
    if (this.axis !== "x") return

    this.dx = dx
    const blocked = (dx > 0 && !this.hasOlderTarget) || (dx < 0 && !this.hasNewerTarget)
    this.imageTarget.style.transform = `translateX(${blocked ? dx * RESISTANCE : dx}px)`
  }

  end() {
    if (!this.tracking) return

    this.tracking = false
    const threshold = Math.min(MAX_THRESHOLD, (this.element.clientWidth || window.innerWidth) * 0.2)
    if (this.dx > threshold && this.hasOlderTarget) return this.go("older", "pointer")
    if (this.dx < -threshold && this.hasNewerTarget) return this.go("newer", "pointer")
    this.cancel()
  }

  // Pinch (a second finger) or a gesture taken by the browser: the photo goes back in place.
  cancel() {
    this.tracking = false
    if (this.hasImageTarget) this.imageTarget.style.transform = ""
  }

  key(event) {
    if (event.defaultPrevented || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return
    if (event.target.closest?.("input, textarea, select, [contenteditable]")) return
    if (document.querySelector("dialog[open]")) return

    if (event.key === "ArrowLeft" && this.hasOlderTarget) {
      event.preventDefault()
      this.go("older", "key")
    } else if (event.key === "ArrowRight" && this.hasNewerTarget) {
      event.preventDefault()
      this.go("newer", "key")
    }
  }

  // A tap or Enter on a link: remember the direction too. A click from the keyboard has no detail (no click count).
  mark(event) {
    if (this.navigating) return // the click of go() below: already remembered

    const direction = event.currentTarget === this.olderTargets[0] ? "older" : "newer"
    this.remember(direction, event.detail === 0 ? "key" : "pointer")
  }

  go(direction, input) {
    this.remember(direction, input)
    this.navigating = true
    this[`${direction}Target`].click()
    this.navigating = false
  }

  remember(direction, input) {
    document.documentElement.dataset.photoDirection = direction
    document.documentElement.dataset.photoInput = input
  }

  // From the keyboard, the focus goes back to the link used, or to the other one at the end of the photos.
  restoreFocus() {
    const { photoDirection: direction, photoInput: input } = document.documentElement.dataset
    delete document.documentElement.dataset.photoInput
    if (input !== "key") return

    const same = direction === "older" ? this.olderTargets[0] : this.newerTargets[0]
    const other = direction === "older" ? this.newerTargets[0] : this.olderTargets[0]
    ;(same || other)?.focus({ preventScroll: true })
  }
}