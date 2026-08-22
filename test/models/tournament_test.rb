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

  test "should destroy tournament with matches without foreign key violation" do
    tournament = tournaments(:orange)
    alice = participants(:alice)
    bob = participants(:bob)
    tournament.matches.create!(round: 1, participant1: alice, participant2: bob, winner: alice)
    assert_difference "Tournament.count", -1 do
      tournament.destroy
    end
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

  test "best_predictor should be nil before the tournament ends" do
    tournament = tournaments(:orange)
    alice = participants(:alice)
    bob = participants(:bob)
    match = tournament.matches.create!(round: 1, participant1: alice, participant2: bob,
                                        winner: alice, winner_games: 6, loser_games: 3, status: :finished)
    Prediction.create!(user: users(:michael), match: match, predicted_participant: alice, points: 10)
    tournament.update!(status: :during)
    assert_nil tournament.best_predictor
  end

  test "best_predictor should return the user with the most points after the tournament ends" do
    tournament = tournaments(:orange)
    alice = participants(:alice)
    bob = participants(:bob)
    match = tournament.matches.create!(round: 1, participant1: alice, participant2: bob,
                                        winner: alice, winner_games: 6, loser_games: 3, status: :finished)
    Prediction.create!(user: users(:michael), match: match, predicted_participant: alice, points: 10)
    Prediction.create!(user: users(:archer), match: match, predicted_participant: bob, points: 0)
    tournament.update!(status: :after)
    assert_equal users(:michael), tournament.best_predictor
  end

  test "passcode should be optional" do
    @tournament.passcode = nil
    assert @tournament.valid?
    assert_nil @tournament.passcode_digest
  end

  test "passcode should be rejected if not 4 digits" do
    @tournament.passcode = "12a4"
    assert_not @tournament.valid?
    @tournament.passcode = "123"
    assert_not @tournament.valid?
  end

  test "passcode should be hashed and authenticatable when valid" do
    @tournament.passcode = "1234"
    assert @tournament.valid?
    @tournament.save!
    assert_not_nil @tournament.passcode_digest
    assert @tournament.authenticate_passcode("1234")
    assert_not @tournament.authenticate_passcode("0000")
  end
end
