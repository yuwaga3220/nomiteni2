require "test_helper"

class PlayersInterfaceTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
    @tournament = tournaments(:orange)
    log_in_as(@user)
  end

  test "should show player registration form to owner" do
    get tournament_path(@tournament)
    assert_select "form[action=?]", tournament_players_path(@tournament)
  end

  test "should add and display player" do
    assert_difference "Player.count", 1 do
      post tournament_players_path(@tournament),
           params: { player: { name: "新選手" } }
    end
    assert_redirected_to tournament_path(@tournament)
    follow_redirect!
    assert_match "新選手", response.body
  end

  test "should not add player with blank name" do
    assert_no_difference "Player.count" do
      post tournament_players_path(@tournament), params: { player: { name: "" } }
    end
    assert_redirected_to tournament_path(@tournament)
    follow_redirect!
    assert_select "div.alert-danger"
  end

  test "should delete player" do
    player = players(:alice)
    assert_difference "Player.count", -1 do
      delete tournament_player_path(@tournament, player)
    end
    assert_redirected_to tournament_path(@tournament)
  end

  test "should not show add/delete controls to non-owner" do
    log_in_as(users(:archer))
    get tournament_path(@tournament)
    assert_select "form[action=?]", tournament_players_path(@tournament), count: 0
  end
end
