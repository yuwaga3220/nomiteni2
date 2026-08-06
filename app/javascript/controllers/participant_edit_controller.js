import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form", "input"]

  edit() {
    this.displayTarget.style.display = "none"
    this.formTarget.style.display = "flex"
    this.inputTarget.focus()
  }

  cancel() {
    this.formTarget.style.display = "none"
    this.displayTarget.style.display = ""
  }
}
