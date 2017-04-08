require 'integration_helper'

class UsersIndexTest < IntegrationHelper
  
  def setup
    @user = users(:c1)
  end

  test "index including pagination" do

    #I am commenting this test out for now cause we don't use this feature but I'm pretty sure we'll use pagination
    #again in the future so I'll leave these codes in place
    return

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
