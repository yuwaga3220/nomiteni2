require "test_helper"

class PlayerTest < ActiveSupport::TestCase
  def setup
    @tournament = tournaments(:orange)
    @player = @tournament.players.build(name: "田中太郎")
  end

  test "should be valid" do
    assert @player.valid?
  end

  test "tournament_id should be present" do
    @player.tournament_id = nil
    assert_not @player.valid?
  end

  test "name should be present" do
    @player.name = "   "
    assert_not @player.valid?
  end

  test "name should be at most 50 characters" do
    @player.name = "a" * 51
    assert_not @player.valid?
  end

  test "name should be unique within tournament" do
    @player.save
    duplicate = @tournament.players.build(name: @player.name)
    assert_not duplicate.valid?
  end

  test "same name in different tournament should be valid" do
    @player.save
    other = tournaments(:ants).players.build(name: @player.name)
    assert other.valid?
  end

  test "position should be nil or positive integer" do
    @player.position = 0
    assert_not @player.valid?
    @player.position = -1
    assert_not @player.valid?
    @player.position = nil
    assert @player.valid?
    @player.position = 1
    assert @player.valid?
  end
end
