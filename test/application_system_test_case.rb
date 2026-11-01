require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # ログインや画面遷移に2秒以上かかる環境（CI など）でも、待ち切れずに落ちないようにする
  Capybara.default_max_wait_time = 10

  private

    # Stimulus コントローラの接続前にクリックすると何も起きないため、接続を待つ
    def wait_for_stimulus(selector, identifier)
      connected = <<~JS
        (() => {
          const elements = Array.from(document.querySelectorAll(#{selector.to_json}));
          return elements.length > 0 &&
            elements.every(element => window.Stimulus?.getControllerForElementAndIdentifier(element, #{identifier.to_json}));
        })()
      JS
      Timeout.timeout(Capybara.default_max_wait_time) { sleep 0.05 until evaluate_script(connected) }
    end
end
