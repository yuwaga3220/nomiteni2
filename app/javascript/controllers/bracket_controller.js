import { Controller } from "@hotwired/stimulus"
import { createBracket } from "bracketry"

export default class extends Controller {
  static values = { data: Object }

  connect() {
    this.bracket = createBracket(this.dataValue, this.element, {
      getMatchElement: (roundIndex, order) => {
        const el = document.getElementById(`bracket-match-${roundIndex}-${order}`)
        if (el) el.style.display = ""
        return el
      },
      rootBgColor: "#111111",
      wrapperBorderColor: "#333333",
      roundTitleColor: "#888888",
      roundTitlesBorderColor: "#333333",
      matchTextColor: "#e0e0e0",
      connectionLinesColor: "#666666",
      hoveredMatchBorderColor: "#6ab0f5",
      matchStatusBgColor: "#1a1a1a"
    })
  }

  disconnect() {
    this.bracket?.uninstall()
  }
}
