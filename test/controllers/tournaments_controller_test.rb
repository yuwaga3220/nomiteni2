require "test_helper"

class TournamentsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @tournament = tournaments(:orange)
  end

  test "should get new" do
    log_in_as(users(:michael))
    get new_tournament_path
    assert_response :success
  end

  test "should redirect new when not logged in" do
    get new_tournament_path
    assert_redirected_to login_url
  end

  test "should redirect create when not logged in" do
    assert_no_difference "Tournament.count" do
      post tournaments_path, params: { tournament: { title: "春季テニス大会" } }
    end
    assert_redirected_to login_url
  end

  test "should redirect destroy when not logged in" do
    assert_no_difference "Tournament.count" do
      delete tournament_path(@tournament)
    end
    assert_response :see_other
    assert_redirected_to login_url
  end

  test "should redirect destroy for wrong tournament" do
    log_in_as(users(:michael))
    tournament = tournaments(:ants)
    assert_no_difference "Tournament.count" do
      delete tournament_path(tournament)
    end
    assert_response :see_other
    assert_redirected_to root_url
  end

  test "should not update status to after when a match is not finished" do
    @tournament.update!(status: :during)
    @tournament.matches.create!(round: 1, participant1: participants(:alice), participant2: participants(:bob))
    log_in_as(users(:michael))
    patch update_status_tournament_path(@tournament), params: { status: "after" }
    assert_redirected_to tournament_path(@tournament)
    assert_not flash.empty?
    assert_equal "during", @tournament.reload.status
  end

  test "should not update status to after when there are no matches" do
    @tournament.update!(status: :during)
    log_in_as(users(:michael))
    patch update_status_tournament_path(@tournament), params: { status: "after" }
    assert_equal "during", @tournament.reload.status
  end

  test "should keep walkover results when status is changed back to before" do
    alice = participants(:alice)
    bob = participants(:bob)
    carol = participants(:carol)
    final = @tournament.matches.create!(round: 2)
    match1 = @tournament.matches.create!(round: 1, participant1: alice, participant2: bob,
                                          next_match: final, next_slot: 1)
    bob.withdraw
    @tournament.update!(status: :during)
    final.update!(participant2: carol)
    log_in_as(users(:michael))
    patch update_status_tournament_path(@tournament), params: { status: "before" }
    assert_equal alice, match1.reload.winner
    final.reload
    assert_equal alice, final.participant1
    assert_nil final.participant2
  end

  test "should show withdrawn label and walkover on the bracket" do
    final = @tournament.matches.create!(round: 2)
    @tournament.matches.create!(round: 1, participant1: participants(:alice), participant2: participants(:bob),
                                next_match: final, next_slot: 1)
    participants(:bob).withdraw
    log_in_as(users(:michael))
    get tournament_path(@tournament)
    assert_select ".bracket-slot", text: /#{participants(:bob).name}\s*棄権/
    assert_select ".bracket-slot-muted", text: /#{participants(:bob).name}/
    assert_select "div", text: "不戦勝"
    # 不戦勝の勝者が決勝に進出している
    assert_select ".bracket-slot:not(.bracket-slot-empty)", text: /#{participants(:alice).name}/, count: 2
  end

  test "should show withdrawal panel only to owner" do
    log_in_as(users(:michael))
    get tournament_path(@tournament)
    assert_select ".withdrawal-panel"
    log_in_as(users(:archer))
    get tournament_path(@tournament)
    assert_select ".withdrawal-panel", count: 0
  end

  test "should not update status to during when there are no matches" do
    log_in_as(users(:michael))
    patch update_status_tournament_path(@tournament), params: { status: "during" }
    assert_redirected_to tournament_path(@tournament)
    assert_not flash.empty?
    assert_equal "before", @tournament.reload.status
  end

  test "should update status to after when all matches are finished" do
    @tournament.update!(status: :during)
    match = @tournament.matches.create!(round: 1, participant1: participants(:alice), participant2: participants(:bob))
    match.update!(winner: participants(:alice), winner_games: 6, loser_games: 3, status: :finished)
    log_in_as(users(:michael))
    patch update_status_tournament_path(@tournament), params: { status: "after" }
    assert_equal "after", @tournament.reload.status
  end

  test "should broadcast to owner and public streams when status changes" do
    @tournament.matches.create!(round: 1, participant1: participants(:alice), participant2: participants(:bob))
    log_in_as(users(:michael))
    assert_broadcasts("tournament_#{@tournament.id}_owner", 1) do
      assert_broadcasts("tournament_#{@tournament.id}_public", 1) do
        patch update_status_tournament_path(@tournament), params: { status: "during" }
      end
    end
  end

  test "should redirect show to root when passcode is required and not authorized" do
    @tournament.update!(passcode: "1234")
    log_in_as(users(:archer))
    get tournament_path(@tournament)
    assert_redirected_to root_url
  end

  test "should show tournament to owner without passcode even when passcode is set" do
    @tournament.update!(passcode: "1234")
    log_in_as(users(:michael))
    get tournament_path(@tournament)
    assert_response :success
  end

  test "should show tournament to non-owner once session is authorized via passcode" do
    @tournament.update!(passcode: "1234")
    log_in_as(users(:archer))
    post tournament_passcode_path(@tournament), params: { passcode: "1234" }
    assert_redirected_to tournament_path(@tournament)
    get tournament_path(@tournament)
    assert_response :success
  end
end
