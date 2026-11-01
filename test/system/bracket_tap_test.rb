require "application_system_test_case"

class BracketTapSystemTest < ApplicationSystemTestCase
  def setup
    @tournament = tournaments(:orange)
    @tournament.update!(status: :during)
    @alice = participants(:alice)
    @bob = participants(:bob)
    @match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    log_in_as_michael
    visit tournament_path(@tournament)
  end

  test "should add a game by tapping the participant and not open the edit modal" do
    slot("アリス").click
    assert_selector ".bracket-slot", text: /アリス\s*1/
    slot("アリス").click
    assert_selector ".bracket-slot", text: /アリス\s*2/
    assert_selector ".bracket-slot", text: /ボブ\s*0/
    assert_no_selector "#match-result-modal-#{@match.id}", visible: true
    assert_equal [ 2, 0 ], [ @match.reload.participant1_games, @match.participant2_games ]
    assert @match.in_progress?
  end

  test "should subtract a game by long pressing the participant" do
    slot("アリス").click
    slot("アリス").click
    assert_selector ".bracket-slot", text: /アリス\s*2/
    long_press("アリス")
    assert_selector ".bracket-slot", text: /アリス\s*1/
    assert_equal 1, @match.reload.participant1_games
  end

  test "should open the edit modal only from the edit icon and show the live scores" do
    slot("アリス").click
    assert_selector ".bracket-slot", text: /アリス\s*1/
    find("button[aria-label='試合の詳細を編集']").click
    assert_selector "#match-result-modal-#{@match.id}", visible: true
    within("#match-result-modal-#{@match.id} .match-result-score-body") do
      assert_equal "1", find("input[name='participant1_games']").value
      assert_equal "0", find("input[name='participant2_games']").value
    end
  end

  test "should confirm the live score and advance the result" do
    assert_no_button "確定"
    3.times { slot("アリス").click }
    assert_selector ".bracket-slot", text: /アリス\s*3/
    accept_confirm("アリス 3 - 0 ボブ で結果を確定しますか？") { click_button "確定" }
    assert_text "終了"
    @match.reload
    assert_equal @alice, @match.winner
    assert_equal [ 3, 0 ], [ @match.winner_games, @match.loser_games ]
    assert_nil @match.participant1_games
    assert_selector ".bracket-slot", text: /アリス\s*3/
  end

  test "should not show the confirm button when the score is tied" do
    slot("アリス").click
    slot("ボブ").click
    assert_selector ".bracket-slot", text: /ボブ\s*1/
    assert_no_button "確定"
  end

  test "should not add games by tapping a finished match" do
    @match.update!(winner: @alice, winner_games: 6, loser_games: 3, status: :finished)
    visit tournament_path(@tournament)
    slot("ボブ").click
    sleep 0.3
    assert_nil @match.reload.participant2_games
    assert_selector ".bracket-slot", text: /ボブ\s*3/
  end

  private

    def log_in_as_michael
      visit login_path
      fill_in "メールアドレス", with: users(:michael).email
      fill_in "パスワード", with: "password"
      click_button "ログイン"
      assert_no_current_path login_path
    end

    def slot(name)
      find(".matches-scroller .bracket-slot", text: /#{name}/)
    end

    # 長押し（pointerdown → 一定時間待つ → pointerup）を再現する。
    # 長押しの減算でブラケットが差し替わるため、pointerup は要素を取り直して送る
    def long_press(name)
      dispatch = <<~JS
        const type = arguments[1]
        const el = Array.from(document.querySelectorAll(".matches-scroller .bracket-slot"))
                        .find(e => e.textContent.includes(arguments[0]))
        el.dispatchEvent(new PointerEvent(type, { bubbles: true }))
      JS
      execute_script(dispatch, name, "pointerdown")
      sleep 0.8
      execute_script(dispatch, name, "pointerup")
    end
end
