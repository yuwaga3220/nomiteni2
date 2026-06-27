import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["radio", "label"]

  connect() {
    this.updateLabels()
  }

  select(event) {
    this.updateLabels()
  }

  updateLabels() {
    this.radioTargets.forEach(radio => {
      const label = this.element.querySelector(`label[for="${radio.id}"]`)
      if (!label) return
      label.classList.toggle("btn-warning", radio.checked)
      label.classList.toggle("btn-default", !radio.checked)
    })
  }
}
