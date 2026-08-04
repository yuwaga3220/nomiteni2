require "test_helper"

class TournamentPasscodesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @tournament = tournaments(:orange)
    @tournament.update!(passcode: "1234")
  end

  test "should redirect to login when not logged in" do
    post tournament_passcode_path(@tournament), params: { passcode: "1234" }
    assert_redirected_to login_url
  end

  test "should authorize session and redirect to show page when passcode is correct" do
    log_in_as(users(:archer))
    post tournament_passcode_path(@tournament), params: { passcode: "1234", next: "show" }
    assert_redirected_to tournament_path(@tournament)
    assert_not flash[:danger]
  end

  test "should authorize session and redirect to predictions page when next is predictions" do
    log_in_as(users(:archer))
    post tournament_passcode_path(@tournament), params: { passcode: "1234", next: "predictions" }
    assert_redirected_to new_tournament_prediction_path(@tournament)
  end

  test "should not authorize session when passcode is wrong" do
    log_in_as(users(:archer))
    post tournament_passcode_path(@tournament), params: { passcode: "0000" }
    assert_redirected_to root_url
    assert_not flash[:danger].nil?
    get tournament_path(@tournament)
    assert_redirected_to root_url
  end
end
