require 'test_helper'

class PartnerUsersControllerTest < ActionController::TestCase

  test "should create new partner user if user does not already exist" do
    log_in_as(users(:a1))
    user_count = User.count
    post :create, name: "bob", email: "bob@b.com", dropsite: Dropsite.first
    user = assigns(:user)
    assert_equal user_count + 1, User.count
    bob = User.find_by(email: "bob@b.com")
    assert bob
    assert bob.id > 0
    assert_response :redirect
    assert_redirected_to partner_users_index_path
  end

  test "should not create new partner user if user already exists but should update the name and partner user attribute" do
    log_in_as(users(:a1))
    c1 = users(:c1)    
    assert_equal "c1", c1.name
    user_count = User.count
    post :create, name: "bob", email: "c1@c.com"    
    user = assigns(:user)
    assert_equal user_count, User.count
    bob = User.find_by(email: "c1@c.com")
    assert_equal "bob", bob.name
    c1.reload
    assert_equal c1, bob
    assert bob
    assert bob.id > 0
    assert_response :redirect
    assert_redirected_to partner_users_index_path
  end

end
