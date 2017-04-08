require 'integration_helper'

class UsersLoginTest < IntegrationHelper
  # test "the truth" do
  #   assert true
  # end

  def setup
    @user = users(:c1)
  end

  test "login with invalid information" do
  	get login_path
  	assert_template 'sessions/new'
  	post login_path, params: {session: { email: "", password: "" }}
  	assert_template 'sessions/new'
  	assert_not flash.empty?
  	get root_path
  	assert flash.empty?
  end

  test "login with valid information" do
    get_access_for(@user)
    get login_path
    post login_path, params: {session: { email: @user.email, password: 'dogdog' }}
    assert_redirected_to root_path
    follow_redirect!
    assert_template 'static_pages/home'
    assert_select "a[href=?]", login_path, count: 0
    assert_select "a[href=?]", logout_path
    assert_select "a[href=?]", subscriptions_path
  end

  test "login with valid information followed by logout" do
    get_access_for(@user)
    get login_path
    post login_path, params: {session: { email: @user.email, password: 'dogdog' }}
    assert is_logged_in?
    assert_redirected_to root_path
    follow_redirect!
    assert_template 'static_pages/home'
    assert_select "a[href=?]", login_path, count: 0
    assert_select "a[href=?]", logout_path
    assert_select "a[href=?]", subscriptions_path
    delete logout_path
    assert_not is_logged_in?
    assert_redirected_to root_url
    # Simulate a user clicking logout in a second window.
    delete logout_path
    follow_redirect!
    assert_select "a[href=?]", login_path
    assert_select "a[href=?]", logout_path,      count: 0
    assert_select "a[href=?]", user_path(@user), count: 0
  end

  test "login with remembering" do
    log_in_as(@user, remember_me: '1')
    assert_not_nil cookies['remember_token']
  end

  test "login without remembering" do
    log_in_as(@user, remember_me: '0')
    assert_nil cookies['remember_token']
  end
end
