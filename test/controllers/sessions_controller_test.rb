require 'test_helper'

class SessionsControllerTest < ActionDispatch::IntegrationTest

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
    follow_redirect!
    assert_template 'static_pages/home'
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

    #log in as admin
    admin = users(:a1)
    assert admin
    log_in_as(admin)
    #spoof user
    c1 = users(:c1)
    post sessions_spoof_path, params: {email: c1.email}
    follow_redirect!
    assert_template 'static_pages/home'

    assert_select 'div#spoofBanner', "Spoofing user #{c1.email}"
    current_user = assigns(:current_user)
    assert_equal c1, current_user

  end

end
