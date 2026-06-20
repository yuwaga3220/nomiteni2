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

  test "position should be nil or positive integer" do
    @participant.position = 0
    assert_not @participant.valid?
    @participant.position = -1
    assert_not @participant.valid?
    @participant.position = nil
    assert @participant.valid?
    @participant.position = 99
    assert @participant.valid?
  end
end
