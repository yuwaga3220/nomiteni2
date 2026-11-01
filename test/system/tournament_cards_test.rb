require "application_system_test_case"

class TournamentCardsSystemTest < ApplicationSystemTestCase
  def setup
    @tournament = tournaments(:orange)
    # スマートフォン幅（375px）で表示する
    current_window.resize_to(375, 800)
  end

  def teardown
    current_window.resize_to(1400, 1400)
    Capybara.raise_server_errors = true
  end

  test "should align buttons on a normal tournament card" do
    visit root_path
    assert_card_buttons_aligned(@tournament)
  end

  test "should align buttons on an owner's tournament card" do
    log_in_as_with_browser(users(:michael))
    visit root_path
    assert_selector "#tournament-#{@tournament.id} a", text: "管理画面"
    assert_card_buttons_aligned(@tournament)
  end

  test "should align buttons on a passcode protected tournament card and open the modal" do
    @tournament.update!(passcode: "1234")
    visit root_path
    assert_card_buttons_aligned(@tournament)
    within "#tournament-#{@tournament.id}" do
      click_link "試合状況"
      assert_selector ".modal", visible: true
      assert_text "パスコードを入力"
    end
  end

  test "should align buttons on a tournament card with an image" do
    # ImageMagick のない環境では背景画像の変換に失敗するが、ボタンの配置の確認には影響しない
    Capybara.raise_server_errors = false
    @tournament.image.attach(io: File.open(file_fixture("kitten.jpg")), filename: "kitten.jpg",
                             content_type: "image/jpeg")
    visit root_path
    assert_selector "#tournament-#{@tournament.id}.tournament-card-with-image"
    assert_card_buttons_aligned(@tournament)
  end

  private

    def log_in_as_with_browser(user)
      visit login_path
      fill_in "メールアドレス", with: user.email
      fill_in "パスワード", with: "password"
      click_button "ログイン"
      assert_no_current_path login_path
    end

    # カード内の2つのボタンの上端・下端・幅が揃っているか確かめる
    # （パスコード用モーダル内の「入室する」ボタンは対象外）
    def assert_card_buttons_aligned(tournament)
      selector = "#tournament-#{tournament.id} .tournament-card-actions > .btn, " \
                 "#tournament-#{tournament.id} .tournament-card-actions > span > .btn"
      assert_selector selector, count: 2
      rects = evaluate_script(<<~JS)
        Array.from(document.querySelectorAll("#{selector}"))
          .map(b => { const r = b.getBoundingClientRect(); return { top: r.top, bottom: r.bottom, width: r.width }; })
      JS
      first, second = rects
      assert_in_delta first["top"], second["top"], 1
      assert_in_delta first["bottom"], second["bottom"], 1
      assert_in_delta first["width"], second["width"], 1
    end
end
