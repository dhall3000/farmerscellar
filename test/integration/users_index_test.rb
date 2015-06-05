require 'test_helper'

class UsersIndexTest < ActionDispatch::IntegrationTest
  
  def setup
    @user = users(:c1)
  end

  test "index including pagination" do
    log_in_as(@user)
    get users_path
    assert_template 'users/index'
    if User.count > 25
      assert_select 'div.pagination'
      User.paginate(page: 1).each do |user|
      assert_select 'a[href=?]', user_path(user), text: user.name
      end
    end
  end
end
