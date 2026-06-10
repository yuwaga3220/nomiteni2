require "test_helper"

class TournamentsInterface < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
    log_in_as(@user)
  end
end

class TournamentsInterfaceTest < TournamentsInterface

  test "should paginate tournaments" do
    get root_path
    assert_select 'div.pagination'
  end

  test "should show errors but not create tournament on invalid submission" do
    assert_no_difference 'Tournament.count' do
      post tournaments_path, params: { tournament: { title: "" } }
    end
    assert_select 'div#error_explanation'
    assert_select 'a[href=?]', '/?page=2'
  end

  test "should create a tournament on valid submission" do
    title = "全国テニス選手権大会"
    assert_difference 'Tournament.count', 1 do
      post tournaments_path, params: { tournament: { title: title } }
    end
    assert_redirected_to root_url
    follow_redirect!
    assert_match title, response.body
  end

  test "should have tournament delete links on own profile page" do
    get user_path(@user)
    assert_select 'a', text: '削除'
  end

  test "should be able to delete own tournament" do
    first_tournament = @user.tournaments.paginate(page: 1).first
    assert_difference 'Tournament.count', -1 do
      delete tournament_path(first_tournament)
    end
  end

  test "should not have delete links on other user's profile page" do
    get user_path(users(:archer))
    assert_select 'a', { text: '削除', count: 0 }
  end
end

class TournamentShowTest < TournamentsInterface

  test "should link to tournament show page from listing" do
    get root_path
    tournament = tournaments(:orange)
    assert_select "a[href=?]", tournament_path(tournament)
  end

  test "should display tournament detail on show page" do
    tournament = tournaments(:orange)
    get tournament_path(tournament)
    assert_response :success
    assert_select "title", full_title(tournament.title)
    assert_match tournament.title, response.body
  end
end

class TournamentSidebarTest < TournamentsInterface

  test "should display the right tournament count" do
    get root_path
    assert_match "#{@user.tournaments.count} 大会", response.body
  end
end
