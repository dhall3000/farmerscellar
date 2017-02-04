require 'integration_helper'

class SessionsControllerTest < IntegrationHelper

  test "should spoof user if admin logged in" do
    spoof_user
  end

  test "should not spoof user if admin not logged in" do

    #we're going to log in as c2 and then try to spoof c1
    #nothing should happen except c2 gets redirected to root

    #log in as c2
    c2 = users(:c2)
    assert c2
    log_in_as(c2)

    #try to spoof c1
    c1 = users(:c1)
    post sessions_spoof_path, params: {email: c1.email}
    follow_redirect!
    assert_template 'static_pages/home'

    #nothing should have happened except user gets redirected to root
    assert_select 'div#spoofBanner', count: 0

  end

  test "should unspoof user if admin logged in" do

    spoof_user
    get sessions_unspoof_path
    assert_response :redirect
    assert_redirected_to users_path
    follow_redirect!
    assert_template 'users/index'
    assert_not flash.empty?
    assert_equal "All done spoofing", flash[:success]
    current_user = assigns(:current_user)
    assert_equal users(:a1), current_user    

  end

  test "should not unspoof user if admin not logged in" do

    #log in as c2
    c2 = users(:c2)
    assert c2
    log_in_as(c2)

    #try to spoof c1
    c1 = users(:c1)
    get sessions_unspoof_path
    follow_redirect!
    assert_template 'static_pages/home'

    #nothing should have happened except user gets redirected to root
    assert_select 'div#spoofBanner', count: 0
    assert flash.empty?

  end

  def spoof_user

    c1 = users(:c1)
    get_access_for(c1)

    #log in as admin
    admin = users(:a1)
    get_access_for(admin)
    assert admin
    log_in_as(admin)
    #spoof user
    post sessions_spoof_path, params: {email: c1.email}
    assert_response :redirect
    assert_redirected_to c1
    follow_redirect!
    assert_template 'users/show'

    assert_select 'div#spoofBanner', "Spoofing user #{c1.email}"
    current_user = assigns(:current_user)
    assert_equal c1, current_user

  end

end
