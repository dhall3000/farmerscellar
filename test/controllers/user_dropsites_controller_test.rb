require 'test_helper'

class UserDropsitesControllerTest < ActionController::TestCase

	def setup
		@user = users(:c1)
	end

	test "should redirect if not logged in" do		
		post :create, user_dropsite: {dropsite_id: 1}
		assert_redirected_to login_path
	end

	test "should change dropsites" do		
		#verify user valid
		assert @user.valid?
		#verify dropsite valid
		assert @user.dropsite.valid?
		#save dropsite id
		old_dropsite_id = @user.dropsite.id
		#load different id
		new_dropsite = dropsites(:dropsite2)
		new_dropsite_id = new_dropsite.id
		#verify dropsite ids are different
		assert new_dropsite_id != old_dropsite_id
		#post the dropsite change
		log_in_as(@user)
		post :create, user_dropsite: {dropsite_id: new_dropsite_id}
		#verify the dropsite ids are different			
		assert @user.dropsite.id != old_dropsite_id, "@user.dropsite.id = #{@user.dropsite.id.to_s}, dropsite=#{@user.dropsite.name}, newdropsite=#{new_dropsite.name}, id=#{new_dropsite.id.to_s}"
		assert_equal new_dropsite_id, @user.dropsite.id
		#reload the user object
		@user.reload
		#reverify the dropsite ids are different
		assert @user.dropsite.id != old_dropsite_id
		assert_equal new_dropsite_id, @user.dropsite.id
		#assert redirected back to the tote
		assert_redirected_to tote_items_path
		#assert happy flash appears
		assert_not flash.empty?
		#verify flash contents
  	assert_equal flash[:success], "Your delivery dropsite is now " + @user.dropsite.name		
	end		

end
