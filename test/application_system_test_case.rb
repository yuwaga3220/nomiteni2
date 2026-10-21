require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  # ログインや画面遷移に2秒以上かかる環境（CI など）でも、待ち切れずに落ちないようにする
  Capybara.default_max_wait_time = 10
end
