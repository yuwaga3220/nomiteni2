require "test_helper"

class TournamentTest < ActiveSupport::TestCase
  def setup
    @user = users(:michael)
    # このコードは慣習的に正しくない
    @tournament = @user.tournaments.build(title: "春季テニス大会")
  end

  test "should be valid" do
    assert @tournament.valid?
  end

  test "user id should be present" do
    @tournament.user_id = nil
    assert_not @tournament.valid?
  end

  test "title should be present" do
    @tournament.title = "   "
    assert_not @tournament.valid?
  end

  test "title should be at most 100 characters" do
    @tournament.title = "a" * 101
    assert_not @tournament.valid?
  end

  test "order should be most recent first" do
    assert_equal tournaments(:most_recent), Tournament.first
  end

  test "champion should be nil before the tournament ends" do
    tournament = tournaments(:orange)
    alice = participants(:alice)
    bob = participants(:bob)
    tournament.matches.create!(round: 1, participant1: alice, participant2: bob,
                                winner: alice, winner_games: 6, loser_games: 3, status: :finished)
    tournament.update!(status: :during)
    assert_nil tournament.champion
  end

  test "champion should return the winner of the final match after the tournament ends" do
    tournament = tournaments(:orange)
    alice = participants(:alice)
    bob = participants(:bob)
    tournament.matches.create!(round: 1, participant1: alice, participant2: bob,
                                winner: alice, winner_games: 6, loser_games: 3, status: :finished)
    tournament.update!(status: :after)
    assert_equal alice, tournament.champion
  end
end
