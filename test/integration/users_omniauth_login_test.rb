require "test_helper"

class UsersOmniauthLoginTest < ActionDispatch::IntegrationTest
  test "新規ユーザーがGoogleログインでアカウント作成される" do
    mock_google_auth(email: "newgoogleuser@example.com")
    assert_difference "User.count", 1 do
      get "/auth/google_oauth2/callback"
    end
    assert is_logged_in?
    assert User.last.activated?
    assert_redirected_to root_url
  end

  test "既存の同一メールアカウントに自動連携される" do
    user = users(:michael)
    mock_google_auth(email: user.email)
    assert_no_difference "User.count" do
      get "/auth/google_oauth2/callback"
    end
    assert_equal "google_oauth2", user.reload.provider
    assert is_logged_in?
  end

  test "認証失敗時はログイン画面へリダイレクトされる" do
    OmniAuth.config.mock_auth[:google_oauth2] = :invalid_credentials
    get "/auth/failure"
    assert_not is_logged_in?
    assert_redirected_to login_url
  end
end
