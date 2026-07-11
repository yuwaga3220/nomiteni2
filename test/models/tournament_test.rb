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
end
