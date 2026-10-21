require "test_helper"

class PredictionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @tournament = tournaments(:orange)
    @alice = participants(:alice)
    @bob = participants(:bob)
    @match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
  end

  test "should not show ranking before tournament starts" do
    log_in_as(users(:michael))
    get new_tournament_prediction_path(@tournament)
    assert_select "p", text: "集計前です。大会が始まるとランキングが表示されます。"
  end

  test "should show ranking sorted by total points during tournament" do
    @tournament.update!(status: :during)
    Prediction.create!(user: users(:michael), match: @match, predicted_participant: @alice, points: 4)
    Prediction.create!(user: users(:archer), match: @match, predicted_participant: @bob, points: 8)
    log_in_as(users(:michael))
    get new_tournament_prediction_path(@tournament)
    assert_select "li.list-group-item", count: 2
    names_in_order = css_select("li.list-group-item").map { |li| li.text.strip }
    assert names_in_order[0].start_with?(users(:archer).name)
    assert names_in_order[1].start_with?(users(:michael).name)
  end

  test "should not include users without predictions in ranking" do
    @tournament.update!(status: :during)
    Prediction.create!(user: users(:michael), match: @match, predicted_participant: @alice, points: 4)
    log_in_as(users(:michael))
    get new_tournament_prediction_path(@tournament)
    assert_select "li.list-group-item", count: 1
  end

  test "should show prediction log with correct and incorrect results after a match finishes" do
    other_match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    @tournament.update!(status: :during)
    @match.update!(winner: @alice, winner_games: 6, loser_games: 3, status: :finished)
    other_match.update!(winner: @bob, winner_games: 6, loser_games: 3, status: :finished)
    Prediction.create!(user: users(:michael), match: @match, predicted_participant: @alice, points: 10)
    Prediction.create!(user: users(:michael), match: other_match, predicted_participant: @alice, points: 0)
    log_in_as(users(:michael))
    get new_tournament_prediction_path(@tournament)
    assert_response :success
    assert_select ".prediction-log"
    assert_select ".prediction-log-item", count: 2
    assert_select ".prediction-log .glyphicon-ok", count: 1
    assert_select ".prediction-log .glyphicon-remove", count: 1
    assert_select ".prediction-log-hit-rate", count: 0
  end

  test "should show only own predictions in prediction log when two users predict differently" do
    @tournament.update!(status: :during)
    @match.update!(winner: @alice, winner_games: 6, loser_games: 3, status: :finished)
    Prediction.create!(user: users(:michael), match: @match, predicted_participant: @alice, points: 10)
    Prediction.create!(user: users(:archer), match: @match, predicted_participant: @bob, points: 0)
    log_in_as(users(:michael))
    get new_tournament_prediction_path(@tournament)
    assert_select ".prediction-log-item", count: 1
    assert_select ".prediction-log-user", text: "あなたの予想:", count: 1
    assert_select ".prediction-log .glyphicon-ok", count: 1
    assert_select ".prediction-log .glyphicon-remove", count: 0
    # 他ユーザーの名前や予想内容はログのHTMLに含まれない
    assert_select ".prediction-log" do |log|
      assert_not_includes log.to_html, users(:archer).name
    end
    assert_select ".prediction-log-detail" do |detail|
      assert_includes detail.text, "あなたの予想: #{@alice.name}"
      assert_not_includes detail.text, @bob.name
    end
  end

  test "should not show matches without own prediction in prediction log" do
    @tournament.update!(status: :during)
    @match.update!(winner: @alice, winner_games: 6, loser_games: 3, status: :finished)
    Prediction.create!(user: users(:archer), match: @match, predicted_participant: @bob, points: 0)
    log_in_as(users(:michael))
    get new_tournament_prediction_path(@tournament)
    assert_select ".prediction-log-item", count: 0
    assert_select "p.text-muted", text: "まだ結果が出た試合はありません。"
  end

  test "should not show prediction log before tournament starts" do
    log_in_as(users(:michael))
    get new_tournament_prediction_path(@tournament)
    assert_select ".prediction-log", count: 0
  end

  test "should show the winner of the match with the lowest hit rate as the biggest upset after all matches finish" do
    other_match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    @match.update!(winner: @alice, winner_games: 6, loser_games: 3, status: :finished)
    other_match.update!(winner: @bob, winner_games: 6, loser_games: 3, status: :finished)
    @tournament.update!(status: :after)
    # @matchはmichael/archerとも的中（的中率100%）
    Prediction.create!(user: users(:michael), match: @match, predicted_participant: @alice, points: 10)
    Prediction.create!(user: users(:archer), match: @match, predicted_participant: @alice, points: 10)
    # other_matchはmichaelだけ的中（的中率50%）
    Prediction.create!(user: users(:michael), match: other_match, predicted_participant: @bob, points: 10)
    Prediction.create!(user: users(:archer), match: other_match, predicted_participant: @alice, points: 0)
    log_in_as(users(:michael))
    get new_tournament_prediction_path(@tournament)
    assert_select ".upset-highlight-winner", text: @bob.name
  end

  test "should calculate biggest upset from all users' predictions even if own prediction is missing" do
    other_match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    @match.update!(winner: @alice, winner_games: 6, loser_games: 3, status: :finished)
    other_match.update!(winner: @bob, winner_games: 6, loser_games: 3, status: :finished)
    @tournament.update!(status: :after)
    # @matchはmichaelのみ予想して的中（的中率100%）
    Prediction.create!(user: users(:michael), match: @match, predicted_participant: @alice, points: 10)
    # other_matchはarcherのみ予想して外れ（的中率0%）。michaelは予想していない
    Prediction.create!(user: users(:archer), match: other_match, predicted_participant: @alice, points: 0)
    log_in_as(users(:michael))
    get new_tournament_prediction_path(@tournament)
    assert_select ".upset-highlight-winner", text: @bob.name
    assert_select ".prediction-log-item", count: 1
  end

  test "should show the user with the most points as the best predictionor after all matches finish" do
    other_match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    @match.update!(winner: @alice, winner_games: 6, loser_games: 3, status: :finished)
    other_match.update!(winner: @bob, winner_games: 6, loser_games: 3, status: :finished)
    @tournament.update!(status: :after)
    Prediction.create!(user: users(:michael), match: @match, predicted_participant: @alice, points: 10)
    Prediction.create!(user: users(:michael), match: other_match, predicted_participant: @bob, points: 10)
    Prediction.create!(user: users(:archer), match: @match, predicted_participant: @alice, points: 10)
    Prediction.create!(user: users(:archer), match: other_match, predicted_participant: @alice, points: 0)
    log_in_as(users(:michael))
    get new_tournament_prediction_path(@tournament)
    assert_select ".upset-highlight-label", text: "BEST PREDICTOR"
    assert_select ".upset-highlight-winner", text: users(:michael).name
  end

  test "should not show best predictionor before tournament starts" do
    log_in_as(users(:michael))
    get new_tournament_prediction_path(@tournament)
    assert_select ".upset-highlight-label", text: "BEST PREDICTOR", count: 0
  end

  test "should not show biggest upset before tournament starts" do
    log_in_as(users(:michael))
    get new_tournament_prediction_path(@tournament)
    assert_select ".upset-highlight", count: 0
  end

  test "should not show biggest upset while tournament is still during" do
    @tournament.update!(status: :during)
    @match.update!(winner: @alice, winner_games: 6, loser_games: 3, status: :finished)
    Prediction.create!(user: users(:michael), match: @match, predicted_participant: @bob, points: 0)
    log_in_as(users(:michael))
    get new_tournament_prediction_path(@tournament)
    assert_select ".upset-highlight", count: 0
  end

  test "should redirect predictions page to root when passcode is required and not authorized" do
    @tournament.update!(passcode: "1234")
    log_in_as(users(:archer))
    get new_tournament_prediction_path(@tournament)
    assert_redirected_to root_url
  end

  test "should redirect prediction create to root when passcode is required and not authorized" do
    @tournament.update!(status: :before, passcode: "1234")
    log_in_as(users(:archer))
    assert_no_difference "Prediction.count" do
      post tournament_prediction_path(@tournament), params: { match_id: @match.id, participant_id: @alice.id }
    end
    assert_redirected_to root_url
  end

  test "should replace only the bracket with turbo stream and show the selected participant" do
    log_in_as(users(:michael))
    assert_difference "Prediction.count", 1 do
      post tournament_prediction_path(@tournament), params: { match_id: @match.id, participant_id: @alice.id },
                                                    as: :turbo_stream
    end
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_turbo_stream action: "update", target: "prediction-bracket" do
      assert_select "template .bracket-wrapper[data-bracket-preserve-scroll-value=?]", "true"
      assert_select "template button.bracket-slot-selected", text: @alice.name, count: 1
    end
  end

  test "should delete downstream predictions and reflect them in the turbo stream" do
    carol = participants(:carol)
    dave = participants(:dave)
    final = @tournament.matches.create!(round: 2)
    @match.update!(next_match: final, next_slot: 1)
    other_match = @tournament.matches.create!(round: 1, participant1: carol, participant2: dave,
                                              next_match: final, next_slot: 2)
    michael = users(:michael)
    Prediction.create!(user: michael, match: @match, predicted_participant: @alice)
    Prediction.create!(user: michael, match: other_match, predicted_participant: carol)
    Prediction.create!(user: michael, match: final, predicted_participant: @alice)
    log_in_as(michael)
    post tournament_prediction_path(@tournament), params: { match_id: @match.id, participant_id: @bob.id },
                                                  as: :turbo_stream
    assert_nil michael.predictions.find_by(match: final)
    assert_equal @bob, michael.predictions.find_by(match: @match).predicted_participant
    assert_turbo_stream action: "update", target: "prediction-bracket" do
      # 決勝の予想は消え、選択済みは1回戦の2試合（ボブとキャロル）だけになる
      assert_select "template button.bracket-slot-selected", count: 2
      assert_select "template button.bracket-slot-selected", text: @bob.name, count: 1
      assert_select "template button.bracket-slot-selected", text: carol.name, count: 1
    end
    # 決勝の予想が消えた分、進捗も 3 から 2 に減る
    assert_turbo_stream action: "update", target: "prediction-progress" do
      assert_select "template", text: "予想済み 2 / 3 試合"
    end
  end

  test "should show own prediction progress before tournament starts" do
    other_match = @tournament.matches.create!(round: 1, participant1: participants(:carol),
                                              participant2: participants(:dave))
    Prediction.create!(user: users(:michael), match: @match, predicted_participant: @alice)
    # 他のユーザーの予想は進捗に含まれない
    Prediction.create!(user: users(:archer), match: other_match, predicted_participant: participants(:carol))
    log_in_as(users(:michael))
    get new_tournament_prediction_path(@tournament)
    assert_select "#prediction-progress", text: "予想済み 1 / 2 試合"
  end

  test "should update prediction progress with turbo stream when predicting" do
    log_in_as(users(:michael))
    get new_tournament_prediction_path(@tournament)
    assert_select "#prediction-progress", text: "予想済み 0 / 1 試合"
    post tournament_prediction_path(@tournament), params: { match_id: @match.id, participant_id: @alice.id },
                                                  as: :turbo_stream
    assert_turbo_stream action: "update", target: "prediction-progress" do
      assert_select "template", text: "予想済み 1 / 1 試合"
    end
  end

  test "should show prediction progress without error when no matches exist" do
    @tournament.matches.destroy_all
    log_in_as(users(:michael))
    get new_tournament_prediction_path(@tournament)
    assert_response :success
    assert_select "#prediction-progress", text: "予想済み 0 / 0 試合"
  end

  test "should not show prediction progress during or after tournament" do
    log_in_as(users(:michael))
    %i[during after].each do |status|
      @tournament.update!(status: status)
      get new_tournament_prediction_path(@tournament)
      assert_response :success
      assert_select "#prediction-progress", count: 0
    end
  end

  test "should redirect with an error when predicting via turbo stream outside before status" do
    @tournament.update!(status: :during)
    log_in_as(users(:michael))
    assert_no_difference "Prediction.count" do
      post tournament_prediction_path(@tournament), params: { match_id: @match.id, participant_id: @alice.id },
                                                    as: :turbo_stream
    end
    assert_redirected_to new_tournament_prediction_path(@tournament)
    assert_equal "開催前以外は予想を入力できません", flash[:danger]
  end

  test "should still redirect to predictions page on html request" do
    log_in_as(users(:michael))
    post tournament_prediction_path(@tournament), params: { match_id: @match.id, participant_id: @alice.id }
    assert_redirected_to new_tournament_prediction_path(@tournament)
  end

  test "should wrap the bracket with a target for turbo stream on predictions page" do
    log_in_as(users(:michael))
    get new_tournament_prediction_path(@tournament)
    assert_select "#prediction-bracket .bracket-wrapper[data-bracket-preserve-scroll-value=?]", "false"
  end

  test "should allow predictions page once session is authorized via passcode" do
    @tournament.update!(passcode: "1234")
    log_in_as(users(:archer))
    post tournament_passcode_path(@tournament), params: { passcode: "1234", next: "predictions" }
    get new_tournament_prediction_path(@tournament)
    assert_response :success
  end
end
