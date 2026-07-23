require "test_helper"

class ParticipantsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @tournament = tournaments(:orange)
    @participant = participants(:alice)
  end

  test "should redirect create when not logged in" do
    assert_no_difference "Participant.count" do
      post tournament_participants_path(@tournament), params: { participant: { name: "田中" } }
    end
    assert_redirected_to login_url
  end

  test "should redirect create when wrong user" do
    log_in_as(users(:archer))
    assert_no_difference "Participant.count" do
      post tournament_participants_path(@tournament), params: { participant: { name: "田中" } }
    end
    assert_redirected_to root_url
  end

  test "should redirect destroy when not logged in" do
    assert_no_difference "Participant.count" do
      delete tournament_participant_path(@tournament, @participant)
    end
    assert_redirected_to login_url
  end

  test "should redirect destroy when wrong user" do
    log_in_as(users(:archer))
    assert_no_difference "Participant.count" do
      delete tournament_participant_path(@tournament, @participant)
    end
    assert_redirected_to root_url
  end

  test "should not destroy participant when tournament is not before" do
    @tournament.update!(status: :during)
    log_in_as(users(:michael))
    assert_no_difference "Participant.count" do
      delete tournament_participant_path(@tournament, @participant)
    end
    assert_redirected_to tournament_path(@tournament)
    assert_not flash.empty?
  end
end
