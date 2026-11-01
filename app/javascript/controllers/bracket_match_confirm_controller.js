import { Controller } from "@hotwired/stimulus"

// タップで加算した途中スコアを確認のうえ確定する（結果入力モーダルの「結果を確定」フォームを送信する）
export default class extends Controller {
  static values = { modalId: String, message: String }

  confirm() {
    if (!window.confirm(this.messageValue)) return
    document.querySelector(`#${this.modalIdValue} form[action$="/set_winner"]`)?.requestSubmit()
  }
}
