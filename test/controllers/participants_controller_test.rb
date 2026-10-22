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

  test "should update participant name for owner" do
    log_in_as(users(:michael))
    patch tournament_participant_path(@tournament, @participant), params: { participant: { name: "アリシア" } }
    assert_redirected_to tournament_path(@tournament)
    assert_equal "アリシア", @participant.reload.name
  end

  test "should not update participant name when tournament is not before" do
    @tournament.update!(status: :during)
    log_in_as(users(:michael))
    original_name = @participant.name
    patch tournament_participant_path(@tournament, @participant), params: { participant: { name: "アリシア" } }
    assert_redirected_to tournament_path(@tournament)
    assert_not flash.empty?
    assert_equal original_name, @participant.reload.name
  end

  test "should not update participant name to a blank value" do
    log_in_as(users(:michael))
    original_name = @participant.name
    patch tournament_participant_path(@tournament, @participant), params: { participant: { name: "" } }
    assert_redirected_to tournament_path(@tournament)
    assert_not flash.empty?
    assert_equal original_name, @participant.reload.name
  end

  test "should redirect update when not logged in" do
    original_name = @participant.name
    patch tournament_participant_path(@tournament, @participant), params: { participant: { name: "アリシア" } }
    assert_redirected_to login_url
    assert_equal original_name, @participant.reload.name
  end

  test "should redirect update when wrong user" do
    log_in_as(users(:archer))
    original_name = @participant.name
    patch tournament_participant_path(@tournament, @participant), params: { participant: { name: "アリシア" } }
    assert_redirected_to root_url
    assert_equal original_name, @participant.reload.name
  end

  test "should reorder participants" do
    bob = participants(:bob)
    log_in_as(users(:michael))
    patch reorder_tournament_participants_path(@tournament),
          params: { participant_ids: [ bob.id, @participant.id ] }, as: :json
    assert_response :success
    assert_equal 1, bob.reload.position
    assert_equal 2, @participant.reload.position
  end

  test "should not reorder participants when tournament is not before" do
    @tournament.update!(status: :during)
    bob = participants(:bob)
    log_in_as(users(:michael))
    patch reorder_tournament_participants_path(@tournament),
          params: { participant_ids: [ bob.id, @participant.id ] }, as: :json
    assert_response :unprocessable_entity
    assert_equal 1, @participant.reload.position
  end

  test "should not reorder participants when ids do not match" do
    log_in_as(users(:michael))
    patch reorder_tournament_participants_path(@tournament),
          params: { participant_ids: [ @participant.id ] }, as: :json
    assert_response :unprocessable_entity
  end

  test "should redirect reorder when not logged in" do
    bob = participants(:bob)
    patch reorder_tournament_participants_path(@tournament),
          params: { participant_ids: [ bob.id, @participant.id ] }, as: :json
    assert_redirected_to login_url
  end

  test "should withdraw and cancel withdrawal for owner even during tournament" do
    @tournament.update!(status: :during)
    match = @tournament.matches.create!(round: 1, participant1: @participant, participant2: participants(:bob))
    log_in_as(users(:michael))
    patch tournament_participant_path(@tournament, @participant), params: { participant: { withdrawn: true } }
    assert_redirected_to tournament_path(@tournament)
    assert_not flash[:success].nil?
    assert @participant.reload.withdrawn?
    assert_equal participants(:bob), match.reload.winner
    patch tournament_participant_path(@tournament, @participant), params: { participant: { withdrawn: false } }
    assert_not @participant.reload.withdrawn?
    assert_nil match.reload.winner
  end

  test "should broadcast to owner and public streams when withdrawal is changed" do
    log_in_as(users(:michael))
    assert_broadcasts("tournament_#{@tournament.id}_owner", 1) do
      assert_broadcasts("tournament_#{@tournament.id}_public", 1) do
        patch tournament_participant_path(@tournament, @participant), params: { participant: { withdrawn: true } }
      end
    end
  end

  test "should not withdraw participant when wrong user" do
    log_in_as(users(:archer))
    patch tournament_participant_path(@tournament, @participant), params: { participant: { withdrawn: true } }
    assert_redirected_to root_url
    assert_not @participant.reload.withdrawn?
  end

  test "should not withdraw participant when not logged in" do
    patch tournament_participant_path(@tournament, @participant), params: { participant: { withdrawn: true } }
    assert_redirected_to login_url
    assert_not @participant.reload.withdrawn?
  end

  test "should show an error when withdrawal is rejected" do
    bob = participants(:bob)
    @tournament.matches.create!(round: 1, participant1: @participant, participant2: bob,
                                winner: bob, winner_games: 6, loser_games: 2, status: :finished)
    log_in_as(users(:michael))
    patch tournament_participant_path(@tournament, @participant), params: { participant: { withdrawn: true } }
    assert_redirected_to tournament_path(@tournament)
    assert_not flash[:danger].nil?
    assert_not @participant.reload.withdrawn?
  end
end
