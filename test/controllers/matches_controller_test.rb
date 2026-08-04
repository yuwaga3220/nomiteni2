require "test_helper"

class MatchesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @tournament = tournaments(:orange)
    @alice = participants(:alice)
    @bob = participants(:bob)
  end

  test "should redirect create when not logged in" do
    assert_no_difference "Match.count" do
      post tournament_matches_path(@tournament)
    end
    assert_redirected_to login_url
  end

  test "should redirect create when wrong user" do
    log_in_as(users(:archer))
    assert_no_difference "Match.count" do
      post tournament_matches_path(@tournament)
    end
    assert_redirected_to root_url
  end

  test "should create bracket for power-of-two participant count in registration order" do
    log_in_as(users(:michael))
    assert_difference "Match.count", 1 do
      post tournament_matches_path(@tournament)
    end
    assert_redirected_to tournament_path(@tournament)
    match = @tournament.matches.sole
    assert_equal @alice, match.participant1
    assert_equal @bob, match.participant2
    assert_equal 1, match.round
    assert_nil match.next_match
  end

  test "should broadcast to owner and public streams when bracket is created" do
    log_in_as(users(:michael))
    assert_broadcasts("tournament_#{@tournament.id}_owner", 1) do
      assert_broadcasts("tournament_#{@tournament.id}_public", 1) do
        post tournament_matches_path(@tournament)
      end
    end
  end

  test "should not create bracket when participant count is not power of two" do
    tournament = tournaments(:ants)
    log_in_as(users(:archer))
    assert_no_difference "Match.count" do
      post tournament_matches_path(tournament)
    end
    assert_redirected_to tournament_path(tournament)
    assert_not flash[:danger].nil?
  end

  test "should redirect destroy_all when not logged in" do
    @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    assert_no_difference "Match.count" do
      delete destroy_all_tournament_matches_path(@tournament)
    end
    assert_redirected_to login_url
  end

  test "should redirect destroy_all when wrong user" do
    @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    log_in_as(users(:archer))
    assert_no_difference "Match.count" do
      delete destroy_all_tournament_matches_path(@tournament)
    end
    assert_redirected_to root_url
  end

  test "should destroy all matches for owner" do
    @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    log_in_as(users(:michael))
    assert_difference "Match.count", -1 do
      delete destroy_all_tournament_matches_path(@tournament)
    end
    assert_redirected_to tournament_path(@tournament)
  end

  test "should broadcast to owner and public streams when bracket is destroyed" do
    @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    log_in_as(users(:michael))
    assert_broadcasts("tournament_#{@tournament.id}_owner", 1) do
      assert_broadcasts("tournament_#{@tournament.id}_public", 1) do
        delete destroy_all_tournament_matches_path(@tournament)
      end
    end
  end

  test "should destroy all matches across multiple rounds" do
    tournament = tournaments(:zone)
    log_in_as(users(:archer))
    post tournament_matches_path(tournament)
    assert_difference "Match.count", -3 do
      delete destroy_all_tournament_matches_path(tournament)
    end
    assert_redirected_to tournament_path(tournament)
  end

  test "should not set winner before tournament starts" do
    match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    log_in_as(users(:michael))
    patch set_winner_tournament_match_path(@tournament, match),
          params: { participant1_games: 6, participant2_games: 3 }
    assert_redirected_to tournament_path(@tournament)
    assert_not flash[:danger].nil?
    assert_nil match.reload.winner
  end

  test "should set participant1 as winner when their score is higher" do
    @tournament.update!(status: :during)
    match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    log_in_as(users(:michael))
    patch set_winner_tournament_match_path(@tournament, match),
          params: { participant1_games: 6, participant2_games: 3 }
    assert_redirected_to tournament_path(@tournament)
    match.reload
    assert_equal @alice, match.winner
    assert_equal 6, match.winner_games
    assert_equal 3, match.loser_games
    assert match.finished?
  end

  test "should set participant2 as winner when their score is higher" do
    @tournament.update!(status: :during)
    match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    log_in_as(users(:michael))
    patch set_winner_tournament_match_path(@tournament, match),
          params: { participant1_games: 2, participant2_games: 6 }
    assert_redirected_to tournament_path(@tournament)
    match.reload
    assert_equal @bob, match.winner
    assert_equal 6, match.winner_games
    assert_equal 2, match.loser_games
  end

  test "should broadcast to owner and public streams when winner is set" do
    @tournament.update!(status: :during)
    match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    log_in_as(users(:michael))
    assert_broadcasts("tournament_#{@tournament.id}_owner", 1) do
      assert_broadcasts("tournament_#{@tournament.id}_public", 1) do
        patch set_winner_tournament_match_path(@tournament, match),
              params: { participant1_games: 6, participant2_games: 3 }
      end
    end
  end

  test "should reject tied scores" do
    @tournament.update!(status: :during)
    match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    log_in_as(users(:michael))
    patch set_winner_tournament_match_path(@tournament, match),
          params: { participant1_games: 5, participant2_games: 5 }
    assert_redirected_to tournament_path(@tournament)
    assert_not flash[:danger].nil?
    assert_nil match.reload.winner
  end

  test "should not allow result entry when a participant is missing" do
    @tournament.update!(status: :during)
    match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: nil)
    log_in_as(users(:michael))
    patch set_winner_tournament_match_path(@tournament, match),
          params: { participant1_games: 6, participant2_games: 3 }
    assert_redirected_to tournament_path(@tournament)
    assert_not flash[:danger].nil?
    assert_nil match.reload.winner
  end

  test "should propagate winner to next match" do
    @tournament.update!(status: :during)
    final = @tournament.matches.create!(round: 2)
    match1 = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob,
                                          next_match: final, next_slot: 1)
    log_in_as(users(:michael))
    patch set_winner_tournament_match_path(@tournament, match1),
          params: { participant1_games: 6, participant2_games: 4 }
    assert_equal @alice, final.reload.participant1
  end

  test "should not set winner when the next match has already started" do
    @tournament.update!(status: :during)
    final = @tournament.matches.create!(round: 2, status: :in_progress)
    match1 = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob,
                                          next_match: final, next_slot: 1)
    log_in_as(users(:michael))
    patch set_winner_tournament_match_path(@tournament, match1),
          params: { participant1_games: 6, participant2_games: 4 }
    assert_redirected_to tournament_path(@tournament)
    assert_not flash[:danger].nil?
    assert_nil match1.reload.winner
  end

  test "should not update status when the next match has already started" do
    @tournament.update!(status: :during)
    final = @tournament.matches.create!(round: 2, status: :in_progress)
    match1 = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob,
                                          next_match: final, next_slot: 1, status: :finished,
                                          winner: @alice, winner_games: 6, loser_games: 3)
    log_in_as(users(:michael))
    patch update_status_tournament_match_path(@tournament, match1),
          params: { court: "コートB", status: "pending" }
    assert_redirected_to tournament_path(@tournament)
    assert_not flash[:danger].nil?
    assert match1.reload.finished?
  end

  test "should award 10 points for a correct prediction and 0 for a wrong one" do
    @tournament.update!(status: :during)
    match = @tournament.matches.create!(round: 3, participant1: @alice, participant2: @bob)
    correct = Prediction.create!(user: users(:archer), match: match, predicted_participant: @alice)
    wrong = Prediction.create!(user: users(:lana), match: match, predicted_participant: @bob)
    log_in_as(users(:michael))
    patch set_winner_tournament_match_path(@tournament, match),
          params: { participant1_games: 6, participant2_games: 3 }
    assert_equal 10, correct.reload.points
    assert_equal 0, wrong.reload.points
  end

  test "should redirect set_winner when not logged in" do
    match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    patch set_winner_tournament_match_path(@tournament, match),
          params: { participant1_games: 6, participant2_games: 3 }
    assert_redirected_to login_url
  end

  test "should redirect set_winner when wrong user" do
    match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    log_in_as(users(:archer))
    patch set_winner_tournament_match_path(@tournament, match),
          params: { participant1_games: 6, participant2_games: 3 }
    assert_redirected_to root_url
  end

  test "should update court and status" do
    @tournament.update!(status: :during)
    match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    log_in_as(users(:michael))
    patch update_status_tournament_match_path(@tournament, match),
          params: { court: "コートA", status: "in_progress" }
    assert_redirected_to tournament_path(@tournament)
    match.reload
    assert_equal "コートA", match.court
    assert match.in_progress?
  end

  test "should broadcast to owner and public streams when match status is updated" do
    @tournament.update!(status: :during)
    match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    log_in_as(users(:michael))
    assert_broadcasts("tournament_#{@tournament.id}_owner", 1) do
      assert_broadcasts("tournament_#{@tournament.id}_public", 1) do
        patch update_status_tournament_match_path(@tournament, match),
              params: { court: "コートA", status: "in_progress" }
      end
    end
  end

  test "should reset winner and games when status is reverted to pending" do
    @tournament.update!(status: :during)
    match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob,
                                         winner: @alice, winner_games: 6, loser_games: 3, status: :finished)
    log_in_as(users(:michael))
    patch update_status_tournament_match_path(@tournament, match),
          params: { court: match.court, status: "pending" }
    match.reload
    assert match.pending?
    assert_nil match.winner
    assert_nil match.winner_games
    assert_nil match.loser_games
  end

  test "should not update status before tournament starts" do
    match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    log_in_as(users(:michael))
    patch update_status_tournament_match_path(@tournament, match),
          params: { court: "コートA", status: "in_progress" }
    assert_redirected_to tournament_path(@tournament)
    assert_not flash[:danger].nil?
    assert match.reload.pending?
  end

  test "should reject invalid status value" do
    @tournament.update!(status: :during)
    match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    log_in_as(users(:michael))
    patch update_status_tournament_match_path(@tournament, match),
          params: { court: "コートA", status: "bogus" }
    assert_redirected_to tournament_path(@tournament)
    assert_not flash[:danger].nil?
    assert match.reload.pending?
  end

  test "should redirect update_status when not logged in" do
    match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    patch update_status_tournament_match_path(@tournament, match),
          params: { court: "コートA", status: "in_progress" }
    assert_redirected_to login_url
  end

  test "should redirect update_status when wrong user" do
    match = @tournament.matches.create!(round: 1, participant1: @alice, participant2: @bob)
    log_in_as(users(:archer))
    patch update_status_tournament_match_path(@tournament, match),
          params: { court: "コートA", status: "in_progress" }
    assert_redirected_to root_url
  end
end
