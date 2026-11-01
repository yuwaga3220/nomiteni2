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
    assert_select "div.pagination"
  end

  test "should show errors but not create tournament on invalid submission" do
    assert_no_difference "Tournament.count" do
      post tournaments_path, params: { tournament: { title: "" } }
    end
    assert_template "tournaments/new"
    assert_select "div#error_explanation"
  end

  test "should create a tournament on valid submission" do
    title = "全国テニス選手権大会"
    assert_difference "Tournament.count", 1 do
      post tournaments_path, params: { tournament: { title: title } }
    end
    assert_redirected_to root_url
    follow_redirect!
    assert_match title, response.body
  end

  # 画像付きで作成した大会は、一覧のカード背景にモザイク画像が表示される
  { "kitten.jpg" => "image/jpeg", "tournament.png" => "image/png",
    "tournament.gif" => "image/gif", "tournament.webp" => "image/webp" }.each do |file, content_type|
    test "should show #{content_type} image on tournament card" do
      post tournaments_path, params: { tournament: { title: "画像付き大会",
                                                     image: fixture_file_upload(file, content_type) } }
      tournament = Tournament.first
      assert tournament.image.attached?
      follow_redirect!
      assert_select "#tournament-#{tournament.id}.tournament-card-with-image[style*=?]",
                    "background-image: url("
      # 背景画像のURLをたどり、バリアント（モザイク画像）が実際に生成できることを確認する
      image_url = css_select("#tournament-#{tournament.id}").first["style"][/url\((.+?)\)/, 1]
      get image_url
      follow_redirect! while response.redirect?
      assert_response :success
      assert_equal 1, tournament.image.blob.variant_records.count
    end
  end

  test "should show tournament card without image as before" do
    post tournaments_path, params: { tournament: { title: "画像なし大会" } }
    tournament = Tournament.first
    follow_redirect!
    assert_select "#tournament-#{tournament.id}.tournament-card"
    assert_select "#tournament-#{tournament.id}.tournament-card-with-image", count: 0
    assert_select "#tournament-#{tournament.id}[style]", count: 0
  end

  test "should have tournament delete links on own profile page" do
    get user_path(@user)
    assert_select "a.tournament-card-delete-link"
  end

  test "should be able to delete own tournament" do
    first_tournament = @user.tournaments.paginate(page: 1).first
    assert_difference "Tournament.count", -1 do
      delete tournament_path(first_tournament)
    end
  end

  test "should not have delete links on other user's profile page" do
    get user_path(users(:archer))
    assert_select "a.tournament-card-delete-link", count: 0
  end
end

class TournamentShowAccessTest < ActionDispatch::IntegrationTest
  test "should redirect show when not logged in" do
    tournament = tournaments(:orange)
    get tournament_path(tournament)
    assert_redirected_to login_url
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

  test "should display the champion after the tournament ends" do
    tournament = tournaments(:orange)
    alice = participants(:alice)
    bob = participants(:bob)
    tournament.matches.create!(round: 1, participant1: alice, participant2: bob,
                                winner: alice, winner_games: 6, loser_games: 3, status: :finished)
    tournament.update!(status: :after)
    get tournament_path(tournament)
    assert_select ".upset-highlight-winner", text: alice.name
  end

  test "should not display the champion before the tournament ends" do
    tournament = tournaments(:orange)
    alice = participants(:alice)
    bob = participants(:bob)
    tournament.matches.create!(round: 1, participant1: alice, participant2: bob,
                                winner: alice, winner_games: 6, loser_games: 3, status: :finished)
    tournament.update!(status: :during)
    get tournament_path(tournament)
    assert_select ".upset-highlight", count: 0
  end
end

class GuestTournamentListTest < ActionDispatch::IntegrationTest
  def setup
    @tournament = tournaments(:orange)
  end

  test "should show tournament list on home when not logged in" do
    get root_path
    assert_response :success
    assert_select "#tournament-#{@tournament.id} .tournament-card-title", text: @tournament.title
    assert_select "h2.tournament-list-heading", text: "開催前（予想受付中）"
  end

  test "should not show delete or calendar links when not logged in" do
    @tournament.update!(held_on: Date.new(2026, 12, 1))
    get root_path
    assert_select "a.tournament-card-delete-link", count: 0
    assert_select "a.tournament-card-calendar-link", count: 0
  end

  test "should redirect to login and forward back to show page after login" do
    get root_path
    assert_select "#tournament-#{@tournament.id} a[href=?]", tournament_path(@tournament), text: "試合状況"
    get tournament_path(@tournament)
    assert_redirected_to login_url
    log_in_as(users(:archer))
    assert_redirected_to tournament_url(@tournament)
  end

  test "should redirect to login and forward back to predictions page after login" do
    get root_path
    assert_select "#tournament-#{@tournament.id} a[href=?]", new_tournament_prediction_path(@tournament)
    get new_tournament_prediction_path(@tournament)
    assert_redirected_to login_url
    log_in_as(users(:archer))
    assert_redirected_to new_tournament_prediction_url(@tournament)
  end

  test "should show passcode protected tournament card when not logged in" do
    @tournament.update!(passcode: "1234")
    get root_path
    assert_response :success
    assert_select "#tournament-#{@tournament.id} .tournament-card-title", text: @tournament.title
    assert_select "#tournament-#{@tournament.id} a[href=?]", tournament_path(@tournament), count: 0
  end

  test "should show home when there are no tournaments and not logged in" do
    Tournament.destroy_all
    get root_path
    assert_response :success
    assert_select ".tournament-card", count: 0
  end
end
