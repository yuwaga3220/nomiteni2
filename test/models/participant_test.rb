require "test_helper"

class ParticipantTest < ActiveSupport::TestCase
  def setup
    @tournament = tournaments(:orange)
    @participant = @tournament.participants.build(name: "田中太郎")
  end

  test "should be valid" do
    assert @participant.valid?
  end

  test "tournament_id should be present" do
    @participant.tournament_id = nil
    assert_not @participant.valid?
  end

  test "name should be present" do
    @participant.name = "   "
    assert_not @participant.valid?
  end

  test "name should be at most 50 characters" do
    @participant.name = "a" * 51
    assert_not @participant.valid?
  end

  test "name should be unique within tournament" do
    @participant.save
    duplicate = @tournament.participants.build(name: @participant.name)
    assert_not duplicate.valid?
  end

  test "same name in different tournament should be valid" do
    @participant.save
    other = tournaments(:ants).participants.build(name: @participant.name)
    assert other.valid?
  end

  test "withdrawn should default to false" do
    assert_not @participant.withdrawn?
  end
end

class ParticipantWithdrawalTest < ActiveSupport::TestCase
  def setup
    @tournament = tournaments(:zone)
    @frank = participants(:frank)
    @grace = participants(:grace)
    @heidi = participants(:heidi)
    @ivan = participants(:ivan)
    @final = @tournament.matches.create!(round: 2)
    @match1 = @tournament.matches.create!(round: 1, participant1: @frank, participant2: @grace,
                                          next_match: @final, next_slot: 1)
    @match2 = @tournament.matches.create!(round: 1, participant1: @heidi, participant2: @ivan,
                                          next_match: @final, next_slot: 2)
  end

  test "withdraw should make the opponent win the match by walkover and advance" do
    assert @grace.withdraw
    assert @grace.reload.withdrawn?
    @match1.reload
    assert @match1.finished?
    assert_equal @frank, @match1.winner
    assert_nil @match1.winner_games
    assert_nil @match1.loser_games
    assert_equal @frank, @final.reload.participant1
  end

  test "withdraw should delete predictions of the walkover match" do
    Prediction.create!(user: users(:michael), match: @match1, predicted_participant: @grace)
    Prediction.create!(user: users(:michael), match: @match2, predicted_participant: @heidi)
    assert_difference "Prediction.count", -1 do
      @grace.withdraw
    end
    assert_empty @match1.predictions
  end

  test "withdraw should cascade walkover when the next opponent has already withdrawn" do
    @match2.update!(winner: @heidi, winner_games: 6, loser_games: 2, status: :finished)
    @final.update!(participant2: @heidi)
    assert @heidi.withdraw
    # 相手が未定のうちは決勝は確定しない
    assert @final.reload.pending?
    assert @grace.withdraw
    @final.reload
    assert @final.finished?
    assert_equal @frank, @final.winner
  end

  test "withdraw should be rejected when both players of the match would be withdrawn" do
    # トーナメントツリー作成前に棄権済みだった選手と同じ1回戦の試合
    @frank.update!(withdrawn: true)
    assert_not @grace.withdraw
    assert_not @grace.errors.empty?
    assert_not @grace.reload.withdrawn?
  end

  test "withdraw should be rejected when the match result is already decided" do
    @match1.update!(winner: @frank, winner_games: 6, loser_games: 1, status: :finished)
    assert_not @grace.withdraw
    assert_not @grace.errors.empty?
    assert_not @grace.reload.withdrawn?
  end

  test "withdraw should be allowed before the bracket is created" do
    tournament = tournaments(:orange)
    alice = participants(:alice)
    assert alice.withdraw
    assert alice.reload.withdrawn?
    assert_empty tournament.matches
  end

  test "cancel_withdrawal should revert the walkover result and advancement" do
    @grace.withdraw
    assert @grace.cancel_withdrawal
    assert_not @grace.reload.withdrawn?
    @match1.reload
    assert @match1.pending?
    assert_nil @match1.winner
    assert_nil @final.reload.participant1
  end

  test "cancel_withdrawal should give walkover to the player when the opponent has withdrawn since" do
    @frank.withdraw
    # 不戦勝で決勝に進んだグレースも棄権する
    @grace.withdraw
    assert @frank.cancel_withdrawal
    @match1.reload
    assert @match1.finished?
    assert_equal @frank, @match1.winner
    assert_equal @frank, @final.reload.participant1
  end

  test "cancel_withdrawal should be rejected when the next match has started" do
    @grace.withdraw
    @final.update!(status: :in_progress)
    assert_not @grace.cancel_withdrawal
    assert_not @grace.errors.empty?
    assert @grace.reload.withdrawn?
    assert_equal @frank, @match1.reload.winner
  end

  test "cancel_withdrawal should not change results of a player who is not withdrawn" do
    @match1.update!(winner: @frank, winner_games: 6, loser_games: 1, status: :finished)
    assert @grace.cancel_withdrawal
    assert @match1.reload.finished?
    assert_equal @frank, @match1.winner
  end
end
