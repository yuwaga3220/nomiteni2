import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item", "badge", "handle"]
  static values = { url: String }

  pointerdown(event) {
    const item = event.currentTarget.closest('[data-participant-reorder-target~="item"]')
    if (!item) return

    event.preventDefault()
    this.draggingEl = item
    this.draggingEl.classList.add("participant-dragging")

    this.boundMove = this.pointermove.bind(this)
    this.boundUp = this.pointerup.bind(this)
    document.addEventListener("pointermove", this.boundMove)
    document.addEventListener("pointerup", this.boundUp)
  }

  pointermove(event) {
    if (!this.draggingEl) return
    event.preventDefault()

    const target = document.elementFromPoint(event.clientX, event.clientY)
                           ?.closest('[data-participant-reorder-target~="item"]')
    if (!target || target === this.draggingEl || !this.itemTargets.includes(target)) return

    const rect = target.getBoundingClientRect()
    const isAfter = event.clientY - rect.top > rect.height / 2
    target.parentNode.insertBefore(this.draggingEl, isAfter ? target.nextSibling : target)
  }

  pointerup() {
    document.removeEventListener("pointermove", this.boundMove)
    document.removeEventListener("pointerup", this.boundUp)
    this.draggingEl?.classList.remove("participant-dragging")
    this.draggingEl = null
    this.renumber()
    this.persist()
  }

  renumber() {
    this.itemTargets.forEach((item, index) => {
      const badge = item.querySelector('[data-participant-reorder-target~="badge"]')
      if (badge) badge.textContent = index + 1
    })
  }

  persist() {
    const ids = this.itemTargets.map(item => item.dataset.id)
    fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        Accept: "application/json"
      },
      body: JSON.stringify({ participant_ids: ids })
    })
  }
}
