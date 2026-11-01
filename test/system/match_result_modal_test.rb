require "application_system_test_case"

class MatchResultModalSystemTest < ApplicationSystemTestCase
  def setup
    @tournament = tournaments(:orange)
    @tournament.update!(status: :during)
    @alice = participants(:alice)
    @bob = participants(:bob)
    @match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    # スマートフォン幅（375px）で表示する
    current_window.resize_to(375, 800)
    log_in_as_michael
  end

  def teardown
    current_window.resize_to(1400, 1400)
  end

  test "should increase and decrease games with tap buttons and never go below zero" do
    open_modal
    within_stepper("アリス") do
      find("button[aria-label='アリスのゲーム数を増やす']").click
      find("button[aria-label='アリスのゲーム数を増やす']").click
      assert_equal "2", find("input").value
      find("button[aria-label='アリスのゲーム数を減らす']").click
      assert_equal "1", find("input").value
      2.times { find("button[aria-label='アリスのゲーム数を減らす']").click }
      assert_equal "0", find("input").value
    end
  end

  test "should have tap buttons large enough for smartphones" do
    open_modal
    sizes = evaluate_script(<<~JS)
      Array.from(document.querySelectorAll("#match-result-modal-#{@match.id} .game-stepper-button"))
        .map(b => { const r = b.getBoundingClientRect(); return { width: r.width, height: r.height }; })
    JS
    assert_equal 4, sizes.size
    sizes.each do |size|
      assert_operator size["width"], :>=, 44
      assert_operator size["height"], :>=, 44
    end
  end

  test "should show games readable inside the modal on smartphones" do
    open_modal
    rects = evaluate_script(<<~JS)
      (() => {
        const modal = document.querySelector("#match-result-modal-#{@match.id} .modal-content").getBoundingClientRect();
        return Array.from(document.querySelectorAll("#match-result-modal-#{@match.id} .game-stepper-input")).map(input => {
          const stepper = input.closest(".game-stepper").getBoundingClientRect();
          return { width: input.getBoundingClientRect().width, height: input.getBoundingClientRect().height, inside: stepper.left >= modal.left && stepper.right <= modal.right };
        });
      })()
    JS
    assert_equal 2, rects.size
    rects.each do |rect|
      assert_operator rect["width"], :>=, 60
      assert_operator rect["height"], :>=, 44
      assert rect["inside"], "ゲーム数の欄がモーダルからはみ出している"
    end
  end

  test "should save the result as finished and advance the winner" do
    open_modal
    within_stepper("アリス") { find("input").set("6") }
    within_stepper("ボブ") { find("input").set("3") }
    save_as_finished
    # 送信後に対戦表へ戻り、スコアが表示されるまで待つ
    assert_selector ".bracket-slot-score", text: "6"
    @match.reload
    assert_equal @alice, @match.winner
    assert_equal 6, @match.winner_games
    assert_equal 3, @match.loser_games
  end

  test "should show an error when the games are tied" do
    open_modal
    within_stepper("アリス") { find("input").set("2") }
    within_stepper("ボブ") { find("input").set("2") }
    save_as_finished
    assert_text "同点の結果は入力できません"
    assert_nil @match.reload.winner
  end

  test "should save court, status and games with one button" do
    open_modal
    assert_equal 1, all("#match-result-modal-#{@match.id} input[type=submit]").size
    within("#match-result-modal-#{@match.id}") do
      fill_in "court", with: "コートA"
      select "試合中", from: "status"
    end
    within_stepper("アリス") { find("input").set("2") }
    within_stepper("ボブ") { find("input").set("2") }
    click_button "保存"
    assert_selector ".bracket-slot-score", text: "2", count: 2
    @match.reload
    assert_equal "コートA", @match.court
    assert @match.in_progress?
    assert_equal [ 2, 2 ], [ @match.participant1_games, @match.participant2_games ]
    assert_nil @match.winner
  end

  test "should show current games as initial values and allow direct input" do
    @match.update!(winner: @bob, winner_games: 6, loser_games: 4, status: :finished)
    open_modal
    within_stepper("アリス") { assert_equal "4", find("input").value }
    within_stepper("ボブ") do
      assert_equal "6", find("input").value
      find("input").set("7")
      find("button[aria-label='ボブのゲーム数を増やす']").click
      assert_equal "8", find("input").value
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

    def open_modal
      visit tournament_path(@tournament)
      trigger = "[data-bracket-match-trigger-modal-id-value='match-result-modal-#{@match.id}']"
      wait_for_stimulus(trigger, "bracket-match-trigger")
      wait_for_stimulus("[data-controller='match-result-modal']", "match-result-modal")
      wait_for_stimulus("[data-controller='game-stepper']", "game-stepper")
      find(trigger).click
      assert_selector "#match-result-modal-#{@match.id}", visible: true
    end

    # 試合状況を「終了」にして保存する（セレクトのフォーカスを外してから押す）
    def save_as_finished
      select "終了", from: "status"
      execute_script("document.activeElement.blur()")
      click_button "保存"
    end

    # 指定した選手のゲーム数入力欄（「−」「＋」と数値欄）の中で操作する
    def within_stepper(name, &block)
      within("#match-result-modal-#{@match.id} .match-result-score-body") do
        label = find("label", text: name)
        within(label.find(:xpath, "..")) { within(".game-stepper", &block) }
      end
    end
end
