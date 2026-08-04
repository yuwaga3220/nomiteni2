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
    @tournament.update!(status: :during)
    @match.update!(winner: @alice, winner_games: 6, loser_games: 3, status: :finished)
    Prediction.create!(user: users(:michael), match: @match, predicted_participant: @alice, points: 10)
    Prediction.create!(user: users(:archer), match: @match, predicted_participant: @bob, points: 0)
    log_in_as(users(:michael))
    get new_tournament_prediction_path(@tournament)
    assert_response :success
    assert_select ".prediction-log"
    assert_select ".prediction-log-item", count: 2
    assert_select ".glyphicon-ok"
    assert_select ".glyphicon-remove"
    assert_select ".prediction-log-hit-rate", count: 0
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

  test "should allow predictions page once session is authorized via passcode" do
    @tournament.update!(passcode: "1234")
    log_in_as(users(:archer))
    post tournament_passcode_path(@tournament), params: { passcode: "1234", next: "predictions" }
    get new_tournament_prediction_path(@tournament)
    assert_response :success
  end
end
