require "test_helper"

class AdminControllerTest < ActionDispatch::IntegrationTest
  def setup
    @admin     = users(:michael)
    @non_admin = users(:archer)
  end

  test "should redirect index when not logged in" do
    get admin_path
    assert_redirected_to login_url
  end

  test "should redirect index when logged in as non-admin" do
    log_in_as(@non_admin)
    get admin_path
    assert_redirected_to root_url
  end

  test "should get index when logged in as admin" do
    log_in_as(@admin)
    get admin_path
    assert_response :success
    assert_select "a[href=?]", users_path
  end
end
