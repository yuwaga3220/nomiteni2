require "test_helper"

class UsersSignup < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.deliveries.clear
  end
end

class UsersSignupTest < UsersSignup
  test "signup page shows google signup above the email form" do
    get signup_path
    assert_select "form[action='/auth/google_oauth2'][method='post']" do
      assert_select "button.btn-primary[data-turbo='false']", text: "Googleでサインアップ"
    end
    # DOM順で「Googleボタン → または → メール/パスワードのフォーム」になっていることを確認
    body = response.body
    google = body.index("/auth/google_oauth2")
    separator = body.index("<p>または</p>")
    form = body.index("action=\"#{users_path}\"")
    assert google < separator
    assert separator < form
  end

  test "invalid signup information" do
    assert_no_difference "User.count" do
      post users_path, params: { user: { name: "",
                                         email: "user@invalid",
                                         password: "foo",
                                         password_confirmation: "bar" } }
    end
    assert_response :unprocessable_entity
    assert_template "users/new"
    assert_select "div#error_explanation"
    assert_select "div.alert-danger"
  end

  test "valid signup information with account activation" do
    assert_difference "User.count", 1 do
      post users_path, params: { user: { name:  "Example User",
                                         email: "user@example.com",
                                         password:              "password",
                                         password_confirmation: "password" } }
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
  end
end

class AccountActivationTest < UsersSignup
  def setup
    super
    post users_path, params: { user: { name:  "Example User",
                                         email: "user@example.com",
                                         password:              "password",
                                         password_confirmation: "password" } }
    @user = assigns(:user)
  end

  test "should not be activated" do
    assert_not @user.activated?
  end

  test "should not be able to log in before account activation" do
    log_in_as(@user)
    assert_not is_logged_in?
  end

  test "should not be able to log in with invalid activation token" do
    get edit_account_activation_path("invalid token", email: @user.email)
    assert_not is_logged_in?
  end

  test "should not be able to log in with invalid email" do
    get edit_account_activation_path(@user.activation_token, email: "wrong")
    assert_not is_logged_in?
  end

  test "should log in successfully with valid activation token and email" do
    get edit_account_activation_path(@user.activation_token, email: @user.email)
    assert @user.reload.activated?
    follow_redirect!
    assert_template "static_pages/home"
    assert is_logged_in?
  end
end
