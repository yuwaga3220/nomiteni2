require "test_helper"

class PlayersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @tournament = tournaments(:orange)
    @player = players(:alice)
  end

  test "should redirect create when not logged in" do
    assert_no_difference "Player.count" do
      post tournament_players_path(@tournament), params: { player: { name: "田中" } }
    end
    assert_redirected_to login_url
  end

  test "should redirect create when wrong user" do
    log_in_as(users(:archer))
    assert_no_difference "Player.count" do
      post tournament_players_path(@tournament), params: { player: { name: "田中" } }
    end
    assert_redirected_to root_url
  end

  test "should redirect destroy when not logged in" do
    assert_no_difference "Player.count" do
      delete tournament_player_path(@tournament, @player)
    end
    assert_redirected_to login_url
  end

  test "should redirect destroy when wrong user" do
    log_in_as(users(:archer))
    assert_no_difference "Player.count" do
      delete tournament_player_path(@tournament, @player)
    end
    assert_redirected_to root_url
  end
end
