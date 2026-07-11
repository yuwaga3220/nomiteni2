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
end
