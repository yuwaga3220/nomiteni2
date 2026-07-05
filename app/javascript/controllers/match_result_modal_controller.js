import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "backdrop", "firstInput"]

  open(event) {
    event.preventDefault()
    this.modalTarget.style.display = "block"
    this.backdropTarget.style.display = "block"
    if (this.hasFirstInputTarget) this.firstInputTarget.focus()
    this.boundClose = this.closeOnEscape.bind(this)
    window.addEventListener("keydown", this.boundClose)
  }

  close() {
    this.modalTarget.style.display = "none"
    this.backdropTarget.style.display = "none"
    if (this.boundClose) window.removeEventListener("keydown", this.boundClose)
  }

  closeOnEscape(event) {
    if (event.key === "Escape") this.close()
  }
}
