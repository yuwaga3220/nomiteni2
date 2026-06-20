require "test_helper"

class MatchesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @tournament = tournaments(:orange)
    @alice = participants(:alice)
    @bob = participants(:bob)
  end

  test "should redirect create when not logged in" do
    assert_no_difference "Match.count" do
      post tournament_matches_path(@tournament),
           params: { positions: { @alice.id => 1, @bob.id => 2 } }
    end
    assert_redirected_to login_url
  end

  test "should redirect create when wrong user" do
    log_in_as(users(:archer))
    assert_no_difference "Match.count" do
      post tournament_matches_path(@tournament),
           params: { positions: { @alice.id => 1, @bob.id => 2 } }
    end
    assert_redirected_to root_url
  end

  test "should create bracket for power-of-two participant count" do
    log_in_as(users(:michael))
    assert_difference "Match.count", 1 do
      post tournament_matches_path(@tournament),
           params: { positions: { @alice.id => 1, @bob.id => 2 } }
    end
    assert_redirected_to tournament_path(@tournament)
    match = @tournament.matches.sole
    assert_equal @alice, match.participant1
    assert_equal @bob, match.participant2
    assert_equal 1, match.round
    assert_nil match.next_match
  end

  test "should not create bracket when participant count is not power of two" do
    tournament = tournaments(:ants)
    log_in_as(users(:archer))
    carol = participants(:carol)
    dave = participants(:dave)
    eve = participants(:eve)
    assert_no_difference "Match.count" do
      post tournament_matches_path(tournament),
           params: { positions: { carol.id => 1, dave.id => 2, eve.id => 3 } }
    end
    assert_redirected_to tournament_path(tournament)
    assert_not flash[:danger].nil?
  end

  test "should not create bracket when positions are blank" do
    log_in_as(users(:michael))
    assert_no_difference "Match.count" do
      post tournament_matches_path(@tournament),
           params: { positions: { @alice.id => "", @bob.id => 2 } }
    end
    assert_redirected_to tournament_path(@tournament)
  end

  test "should not create bracket when positions are duplicated" do
    log_in_as(users(:michael))
    assert_no_difference "Match.count" do
      post tournament_matches_path(@tournament),
           params: { positions: { @alice.id => 1, @bob.id => 1 } }
    end
    assert_redirected_to tournament_path(@tournament)
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

  test "should destroy all matches across multiple rounds" do
    tournament = tournaments(:zone)
    frank = participants(:frank)
    grace = participants(:grace)
    heidi = participants(:heidi)
    ivan = participants(:ivan)
    log_in_as(users(:archer))
    post tournament_matches_path(tournament),
         params: { positions: { frank.id => 1, grace.id => 2, heidi.id => 3, ivan.id => 4 } }
    assert_difference "Match.count", -3 do
      delete destroy_all_tournament_matches_path(tournament)
    end
    assert_redirected_to tournament_path(tournament)
  end
end
