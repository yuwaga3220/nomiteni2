require "application_system_test_case"

class PredictionsSystemTest < ApplicationSystemTestCase
  def setup
    @tournament = tournaments(:orange)
    # ブラケットがスクロールできるだけの試合数を用意する
    32.times do |i|
      p1 = @tournament.participants.create!(name: "選手#{i * 2 + 1}")
      p2 = @tournament.participants.create!(name: "選手#{i * 2 + 2}")
      @tournament.matches.create!(round: 1, participant1: p1, participant2: p2)
    end
  end

  test "should keep scroll position after voting a prediction" do
    visit login_path
    fill_in "メールアドレス", with: users(:michael).email
    fill_in "パスワード", with: "password"
    click_button "ログイン"
    assert_no_current_path login_path
    visit new_tournament_prediction_path(@tournament)
    assert_selector ".matches-scroller"

    # ページとブラケットの両方をスクロールしてから投票する
    execute_script("window.scrollTo(0, 300)")
    execute_script("document.querySelector('.matches-scroller').scrollTop = 800")
    before_window = evaluate_script("window.scrollY")
    before_scroller = evaluate_script("document.querySelector('.matches-scroller').scrollTop")
    assert before_window.positive?
    assert before_scroller.positive?

    # Capybaraのclickは要素へ自動スクロールするため、JSで直接クリックする
    execute_script("Array.from(document.querySelectorAll('.matches-scroller button')).find(b => b.textContent.trim() === '選手63').click()")

    assert_selector "button.bracket-slot-selected", text: "選手63"
    assert_equal before_window, evaluate_script("window.scrollY")
    assert_equal before_scroller, evaluate_script("document.querySelector('.matches-scroller').scrollTop")
  end

  test "should not cover footer links with prediction progress bar" do
    visit login_path
    fill_in "メールアドレス", with: users(:michael).email
    fill_in "パスワード", with: "password"
    click_button "ログイン"
    assert_no_current_path login_path
    visit new_tournament_prediction_path(@tournament)
    assert_selector "#prediction-progress"

    # PC と狭い画面（幅 800px 以下）の両方で、一番下までスクロールしても
    # フッターのリンクが固定バーに隠れない
    [ [ 500, 800 ], [ 1400, 1400 ] ].each do |width, height|
      page.driver.browser.manage.window.resize_to(width, height)
      assert_equal width, evaluate_script("window.innerWidth")
      execute_script("window.scrollTo(0, document.body.scrollHeight)")
      [ "プライバシーポリシー", "お問い合わせ" ].each do |text|
        covered = evaluate_script(<<~JS)
          (() => {
            const link = Array.from(document.querySelectorAll("footer a")).find(a => a.textContent.trim() === "#{text}");
            const rect = link.getBoundingClientRect();
            return document.elementFromPoint(rect.left + rect.width / 2, rect.top + rect.height / 2) !== link;
          })()
        JS
        assert_not covered, "幅 #{width}px で「#{text}」が隠れている"
      end
    end
    click_link "お問い合わせ"
    assert_current_path contact_path
  end

  test "should not overlap tap guide with bracket buttons" do
    visit login_path
    fill_in "メールアドレス", with: users(:michael).email
    fill_in "パスワード", with: "password"
    click_button "ログイン"
    assert_no_current_path login_path
    visit new_tournament_prediction_path(@tournament)
    assert_selector ".prediction-guide", text: "参加者名をタップして勝者を予想しよう"
    assert_selector ".matches-scroller button"

    # PC と狭い画面の両方で、案内（吹き出しの三角を含む）がブラケットより上に収まる
    [ [ 500, 800 ], [ 1400, 1400 ] ].each do |width, height|
      page.driver.browser.manage.window.resize_to(width, height)
      assert_equal width, evaluate_script("window.innerWidth")
      guide_bottom = evaluate_script(<<~JS)
        (() => {
          const guide = document.querySelector(".prediction-guide");
          return guide.getBoundingClientRect().bottom + parseFloat(getComputedStyle(guide, "::after").borderTopWidth);
        })()
      JS
      bracket_top = evaluate_script("document.querySelector('#prediction-bracket').getBoundingClientRect().top")
      assert_operator guide_bottom, :<=, bracket_top, "幅 #{width}px で案内がブラケットに重なっている"
    end
  end
end
