require "test_helper"

class MatchTest < ActiveSupport::TestCase
  def setup
    @tournament = tournaments(:orange)
    @match = @tournament.matches.build(round: 1)
  end

  test "should be valid" do
    assert @match.valid?
  end

  test "round should be present" do
    @match.round = nil
    assert_not @match.valid?
  end

  test "round should be a positive integer" do
    @match.round = 0
    assert_not @match.valid?
  end

  test "result_locked? should be false when there is no next match" do
    assert_not @match.result_locked?
  end

  test "result_locked? should be false when the next match is still pending" do
    final = @tournament.matches.create!(round: 2)
    @match.next_match = final
    assert_not @match.result_locked?
  end

  test "result_locked? should be true when the next match has already started" do
    final = @tournament.matches.create!(round: 2, status: :in_progress)
    @match.next_match = final
    assert @match.result_locked?
  end
end
