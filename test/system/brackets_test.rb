require "application_system_test_case"

class BracketsSystemTest < ApplicationSystemTestCase
  def setup
    @tournament = tournaments(:orange)
    # 64人（6ラウンド）のトーナメントを用意する。決勝から順に、次の試合へのつながりを作る
    next_round_matches = []
    6.downto(1) do |round|
      count = 2**(6 - round)
      next_round_matches = Array.new(count) do |i|
        attrs = { round: round }
        if next_round_matches.any?
          attrs[:next_match] = next_round_matches[i / 2]
          attrs[:next_slot] = i.even? ? 1 : 2
        end
        if round == 1
          attrs[:participant1] = @tournament.participants.create!(name: "選手#{i * 2 + 1}")
          attrs[:participant2] = @tournament.participants.create!(name: "選手#{i * 2 + 2}")
        end
        @tournament.matches.create!(attrs)
      end
    end
  end

  test "should show whole bracket without vertical scroll on owner page" do
    log_in_as_michael
    visit tournament_path(@tournament)
    assert_selector ".matches-scroller", text: "選手64"
    assert_bracket_scrolls_only_horizontally
  end

  test "should show whole bracket without vertical scroll on prediction page" do
    log_in_as_michael
    visit new_tournament_prediction_path(@tournament)
    assert_selector ".matches-scroller button", text: "選手64"
    assert_bracket_scrolls_only_horizontally
  end

  test "should not overflow page horizontally on smartphone width" do
    log_in_as_michael
    page.driver.browser.manage.window.resize_to(375, 800)
    [ tournament_path(@tournament), new_tournament_prediction_path(@tournament) ].each do |path|
      visit path
      assert_selector ".matches-scroller", text: "選手64"
      assert_operator evaluate_script("document.documentElement.scrollWidth"), :<=,
                      evaluate_script("document.documentElement.clientWidth"), "#{path} でページが横にはみ出している"
      assert_bracket_scrolls_only_horizontally
    end
  end

  private

    def log_in_as_michael
      visit login_path
      fill_in "メールアドレス", with: users(:michael).email
      fill_in "パスワード", with: "password"
      click_button "ログイン"
      assert_no_current_path login_path
    end

    # ブラケット内に縦スクロールが無く下端まで表示され、横にはスクロールできて見出し行が追従する
    def assert_bracket_scrolls_only_horizontally
      scroller = "document.querySelector('.matches-scroller')"
      assert_equal "hidden", evaluate_script("getComputedStyle(#{scroller}).overflowY")
      assert_operator evaluate_script("#{scroller}.scrollHeight"), :<=, evaluate_script("#{scroller}.clientHeight")
      # 最後の1回戦の試合（選手63, 64）がブラケットの表示範囲の中に収まっている
      last_match_bottom = evaluate_script(<<~JS)
        Array.from(#{scroller}.querySelectorAll(".bracket-slot"))
             .find(e => e.textContent.trim().startsWith("選手64")).getBoundingClientRect().bottom
      JS
      assert_operator last_match_bottom, :<=, evaluate_script("#{scroller}.getBoundingClientRect().bottom")

      assert_operator evaluate_script("#{scroller}.scrollWidth"), :>, evaluate_script("#{scroller}.clientWidth")
      execute_script("#{scroller}.scrollLeft = 150")
      assert_equal 150, evaluate_script("#{scroller}.scrollLeft")
      # スクロールイベントの反映は非同期なので、見出しが追従するまで待つ
      margin_left = "document.querySelector('.round-titles-wrapper').style.marginLeft"
      Timeout.timeout(Capybara.default_max_wait_time) { sleep 0.05 until evaluate_script(margin_left) == "-150px" }
      assert_equal "-150px", evaluate_script(margin_left)
    end
end
