require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest

  def setup
    ActionMailer::Base.deliveries.clear
  end

  test "invalid signup information" do
    get signup_path
    assert_no_difference 'User.count' do
      post users_path, params: { user: { name:  "",
                               email: "user@invalid",
                               password:              "foo",
                               password_confirmation: "bar" }}
    end
    assert_template 'users/new'
    assert_select 'div#error_explanation'
    assert_select 'div.field_with_errors'
  end

  test "valid signup information with account activation" do
    get signup_path
    assert_difference 'User.count', 1 do
      post users_path, params: {user: { name: "Example User", email: "user@example.com", password: "dogdog", zip: 98033, account_type: 0 }}
    end
    assert_equal 1, ActionMailer::Base.deliveries.size
    user = assigns(:user)    
    assert_not user.activated?
    #log in before activation.
    log_in_as(user)

    #try to checkout before activation.
    #first add a tote item
    posting = postings(:p1)
    post tote_items_path, params: {tote_item: {quantity: 1, posting_id: posting.id}}
    tote_item = assigns(:tote_item)
    post checkouts_path
    assert_redirected_to new_account_activation_path

    # Invalid activation token
    get edit_account_activation_path("invalid token")
    assert_redirected_to root_url
    assert_not flash.empty?
    assert_equal "Invalid activation link", flash[:danger]
    
    # Valid token, wrong email
    get edit_account_activation_path(user.activation_token, email: 'wrong')
    assert_not user.reload.activated?
    
    # Valid activation token
    get edit_account_activation_path(user.activation_token, email: user.email)
    assert user.reload.activated?
    follow_redirect!    
    get_access_for(user)
    get user_path(user)
    assert_template 'users/show'
    assert is_logged_in?
  end
end