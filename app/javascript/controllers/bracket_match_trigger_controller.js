import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { modalId: String }

  open(event) {
    event.preventDefault()
    document.getElementById(this.modalIdValue)?.dispatchEvent(new CustomEvent("bracket-match:open", { bubbles: true }))
  }
}
