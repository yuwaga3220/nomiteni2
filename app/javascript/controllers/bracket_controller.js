import { Controller } from "@hotwired/stimulus"
import { createBracket } from "bracketry"

// 予想の投票でブラケットが差し替えられた後に復元するため、直近のスクロール位置を覚えておく
// （disconnect時には要素がDOMから外れていて位置を読めないので、スクロールの度に記録する）
let lastScrollPosition = { left: 0, top: 0 }

export default class extends Controller {
  static values = { data: Object, preserveScroll: Boolean }

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
      connectionLinesColor: "#4a4a4a",
      highlightedConnectionLinesColor: "#623fbc",
      hoveredMatchBorderColor: "#623fbc",
      matchStatusBgColor: "#1a1a1a"
    })

    // ボタンでのページ送りではなく横スクロールで見たいので、
    // 見出し行(round-titles-wrapper)のスクロール位置を本体(matches-scroller)に同期させる
    this.scroller = this.element.querySelector(".matches-scroller")
    this.titlesWrapper = this.element.querySelector(".round-titles-wrapper")
    this.syncTitlesScroll = () => {
      this.titlesWrapper.style.marginLeft = `-${this.scroller.scrollLeft}px`
      lastScrollPosition = { left: this.scroller.scrollLeft, top: this.scroller.scrollTop }
    }
    this.scroller?.addEventListener("scroll", this.syncTitlesScroll)

    // Turbo Streamで差し替えられた場合は、投票前のスクロール位置に戻す
    // （通常の表示では現在位置を記録し直し、以前のページの位置が残らないようにする）
    if (!this.scroller) return
    if (this.preserveScrollValue) {
      this.scroller.scrollLeft = lastScrollPosition.left
      this.scroller.scrollTop = lastScrollPosition.top
    }
    this.syncTitlesScroll()
  }

  disconnect() {
    this.scroller?.removeEventListener("scroll", this.syncTitlesScroll)
    this.bracket?.uninstall()
  }
}
