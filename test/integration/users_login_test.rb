require "test_helper"

class UsersLogin < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
  end
end

class InvalidPasswordTest < UsersLogin
  test "login path" do
    get login_path
    assert_template "sessions/new"
  end

  test "remember me checkbox with help text" do
    get login_path
    # ラベル全体でオン/オフできるよう、チェックボックスをラベル内に置く
    assert_select ".remember-me label[for=?]", "session_remember_me" do
      assert_select "input[type=checkbox]#session_remember_me[aria-describedby=?]",
                    "remember_me_help"
      assert_select "span", "ログインしたままにする"
    end
    # 初期値はチェックなし
    assert_select "input#session_remember_me[checked]", count: 0
    assert_select "#remember_me_help", /次回から自動でログインします/
  end

  test "login with valid email/invalid password" do
    post login_path, params: { session: { email:    @user.email,
                                          password: "invalid" } }
    assert_not is_logged_in?
    assert_template "sessions/new"
    assert_not flash.empty?
    get root_path
    assert flash.empty?
  end
end

class ValidLogin < UsersLogin
  def setup
    super
    post login_path, params: { session: { email:    @user.email,
                                          password: "password" } }
  end
end

class ValidLoginTest < ValidLogin
  test "valid login" do
    assert is_logged_in?
    assert_redirected_to root_url
  end

  test "redirect after login" do
    follow_redirect!
    assert_template "static_pages/home"
    assert_select "a[href=?]", login_path, count: 0
    assert_select "a[href=?]", logout_path
  end
end

class Logout < ValidLogin
  def setup
    super
    delete logout_path
  end
end

class LogoutTest < Logout
  test "successful logout" do
    assert_not is_logged_in?
    assert_response :see_other
    assert_redirected_to root_url
  end

  test "redirect after logout" do
    follow_redirect!
    assert_select "a[href=?]", login_path
    assert_select "a[href=?]", logout_path,      count: 0
    assert_select "a[href=?]", user_path(@user), count: 0
  end

  test "should still work after logout in second window" do
    delete logout_path
    assert_redirected_to root_url
  end
end

class RememberingTest < UsersLogin
  test "login with remembering" do
    log_in_as(@user, remember_me: "1")
    assert_equal cookies[:remember_token], assigns(:user).remember_token
  end

  test "login without remembering" do
    log_in_as(@user, remember_me: "1")
    log_in_as(@user, remember_me: "0")
    assert cookies[:remember_token].blank?
  end
end
