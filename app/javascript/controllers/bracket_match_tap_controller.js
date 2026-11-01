import { Controller } from "@hotwired/stimulus"

// ブラケットの選手欄をタップするとゲーム数を+1、長押しすると-1する（途中スコアとして保存）
const LONG_PRESS_MS = 500

export default class extends Controller {
  static values = { url: String }

  start(event) {
    this.longPressed = false
    this.clearTimer()
    this.timer = setTimeout(() => {
      this.longPressed = true
      this.send(event.params.slot, -1)
    }, LONG_PRESS_MS)
  }

  end(event) {
    if (this.timer === undefined) return
    this.clearTimer()
    if (!this.longPressed) this.send(event.params.slot, 1)
  }

  cancel() {
    this.clearTimer()
  }

  // 長押しで出るコンテキストメニュー（スマホ）を出さない
  suppress(event) {
    event.preventDefault()
  }

  clearTimer() {
    clearTimeout(this.timer)
    this.timer = undefined
  }

  async send(slot, delta) {
    const response = await fetch(this.urlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content,
        "Accept": "text/vnd.turbo-stream.html",
        "Content-Type": "application/x-www-form-urlencoded"
      },
      body: new URLSearchParams({ slot, delta })
    })
    if (response.ok) window.Turbo.renderStreamMessage(await response.text())
  }
}
