require "test_helper"

class SiteLayoutTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:michael)
  end

  test "layout links" do
    get root_path
    assert_template "static_pages/home"
    assert_select "a[href=?]", root_path, count: 2
    assert_select "a[href=?]", contact_path
    get contact_path
    assert_select "title", full_title("お問い合わせ")
    get signup_path
    assert_select "title", full_title("アカウント作成")
  end

  test "layout links when logged out" do
    get root_path
    assert_select "a[href=?]", root_path, minimum: 1
    assert_select "a[href=?]", login_path
    assert_select "a[href=?]", users_path, count: 0
    assert_select "a[href=?]", logout_path, count: 0
    assert_select "a[href=?]", user_path(@user), count: 0
    assert_select "a[href=?]", edit_user_path(@user), count: 0
  end

  test "layout links when logged in" do
    log_in_as(@user)
    get root_path   # ログイン直後はプロフィールに飛ぶので、レイアウト確認用に別ページへ
    assert_select "a[href=?]", users_path
    assert_select "a[href=?]", user_path(@user)
    assert_select "a[href=?]", edit_user_path(@user)
    assert_select "a[href=?]", logout_path
    assert_select "a[href=?]", login_path, count: 0
  end
end
