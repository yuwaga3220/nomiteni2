require "test_helper"

class LineBrowserTest < ActionDispatch::IntegrationTest
  LINE_USER_AGENT = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 " \
                    "(KHTML, like Gecko) Mobile/15E148 Safari Line/14.0.0".freeze

  test "should redirect LINE in-app browser to open externally" do
    get root_path, headers: { "User-Agent" => LINE_USER_AGENT }
    assert_redirected_to root_url(openExternalBrowser: 1)
  end

  test "should keep path and query when redirecting" do
    get users_path(page: 2), headers: { "User-Agent" => LINE_USER_AGENT }
    assert_redirected_to users_url(page: 2, openExternalBrowser: 1)
  end

  test "should not redirect again when the parameter is present" do
    get root_path(openExternalBrowser: 1), headers: { "User-Agent" => LINE_USER_AGENT }
    assert_response :success
  end

  test "should not redirect other browsers" do
    get root_path, headers: { "User-Agent" => "Mozilla/5.0 (iPhone) Safari/604.1" }
    assert_response :success
  end

  test "should not redirect POST requests from LINE" do
    post login_path, params: { session: { email: "", password: "" } },
                     headers: { "User-Agent" => LINE_USER_AGENT }
    assert_response :unprocessable_entity
  end
end
