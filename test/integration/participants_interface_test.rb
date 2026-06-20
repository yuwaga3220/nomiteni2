require "test_helper"

class ParticipantsInterfaceTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
    @tournament = tournaments(:orange)
    log_in_as(@user)
  end

  test "should show participant registration form to owner" do
    get tournament_path(@tournament)
    assert_select "form[action=?]", tournament_participants_path(@tournament)
  end

  test "should add and display participant" do
    assert_difference "Participant.count", 1 do
      post tournament_participants_path(@tournament),
           params: { participant: { name: "新選手" } }
    end
    assert_redirected_to tournament_path(@tournament)
    follow_redirect!
    assert_match "新選手", response.body
  end

  test "should not add participant with blank name" do
    assert_no_difference "Participant.count" do
      post tournament_participants_path(@tournament), params: { participant: { name: "" } }
    end
    assert_redirected_to tournament_path(@tournament)
    follow_redirect!
    assert_select "div.alert-danger"
  end

  test "should delete participant" do
    participant = participants(:alice)
    assert_difference "Participant.count", -1 do
      delete tournament_participant_path(@tournament, participant)
    end
    assert_redirected_to tournament_path(@tournament)
  end

  test "should not show add/delete controls to non-owner" do
    log_in_as(users(:archer))
    get tournament_path(@tournament)
    assert_select "form[action=?]", tournament_participants_path(@tournament), count: 0
  end
end
