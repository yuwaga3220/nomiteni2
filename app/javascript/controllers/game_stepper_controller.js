import { Controller } from "@hotwired/stimulus"

// ゲーム数を「−」「＋」ボタンで増減する（0未満にはならない）。数値の直接入力もそのまま使える
export default class extends Controller {
  static targets = ["input"]

  increment() {
    this.change(1)
  }

  decrement() {
    this.change(-1)
  }

  change(delta) {
    const current = parseInt(this.inputTarget.value, 10) || 0
    this.inputTarget.value = Math.max(0, current + delta)
  }
}
