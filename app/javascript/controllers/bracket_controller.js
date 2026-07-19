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
      navButtonsPosition: "hidden",
      rootBgColor: "#111111",
      wrapperBorderColor: "#333333",
      roundTitleColor: "#888888",
      roundTitlesBorderColor: "#333333",
      matchTextColor: "#e0e0e0",
      connectionLinesColor: "#666666",
      hoveredMatchBorderColor: "#ff2fb0",
      matchStatusBgColor: "#1a1a1a"
    })

    // ボタンでのページ送りではなく横スクロールで見たいので、
    // 見出し行(round-titles-wrapper)のスクロール位置を本体(matches-scroller)に同期させる
    this.scroller = this.element.querySelector(".matches-scroller")
    this.titlesWrapper = this.element.querySelector(".round-titles-wrapper")
    this.syncTitlesScroll = () => {
      this.titlesWrapper.style.marginLeft = `-${this.scroller.scrollLeft}px`
    }
    this.scroller?.addEventListener("scroll", this.syncTitlesScroll)
  }

  disconnect() {
    this.scroller?.removeEventListener("scroll", this.syncTitlesScroll)
    this.bracket?.uninstall()
  }
}
