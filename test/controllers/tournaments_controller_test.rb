require "test_helper"

class TournamentsControllerTest < ActionDispatch::IntegrationTest

  def setup
    @tournament = tournaments(:orange)
  end

  test "should redirect create when not logged in" do
    assert_no_difference 'Tournament.count' do
      post tournaments_path, params: { tournament: { title: "春季テニス大会" } }
    end
    assert_redirected_to login_url
  end

  test "should redirect destroy when not logged in" do
    assert_no_difference 'Tournament.count' do
      delete tournament_path(@tournament)
    end
    assert_response :see_other
    assert_redirected_to login_url
  end

  test "should redirect destroy for wrong tournament" do
    log_in_as(users(:michael))
    tournament = tournaments(:ants)
    assert_no_difference 'Tournament.count' do
      delete tournament_path(tournament)
    end
    assert_response :see_other
    assert_redirected_to root_url
  end
end