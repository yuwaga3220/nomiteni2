import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "backdrop"]

  open(event) {
    event.preventDefault()
    this.modalTarget.style.display = "block"
    this.backdropTarget.style.display = "block"
  }

  close() {
    this.modalTarget.style.display = "none"
    this.backdropTarget.style.display = "none"
  }
}