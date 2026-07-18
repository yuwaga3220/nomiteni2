import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "backdrop"]

  connect() {
    // トリガー(対戦カード)とはDOM上の親子関係を持たないため、カスタムイベント経由で開く
    this.boundOpen = this.open.bind(this)
    this.element.addEventListener("bracket-match:open", this.boundOpen)
  }

  disconnect() {
    this.element.removeEventListener("bracket-match:open", this.boundOpen)
  }

  open() {
    this.modalTarget.style.display = "flex"
    this.backdropTarget.style.display = "block"
  }

  close() {
    this.modalTarget.style.display = "none"
    this.backdropTarget.style.display = "none"
  }

  closeIfOutside(event) {
    if (event.target === this.modalTarget) this.close()
  }
}
