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
end
