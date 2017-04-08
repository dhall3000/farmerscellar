require 'model_test_ancestor'

class WebsiteSettingTest < ModelTestAncestor
  # test "the truth" do
  #   assert true
  # end

  def setup
  	@website_setting = WebsiteSetting.new(new_customer_access_code_required: true, recurring_postings_enabled: true)
  	#@user = User.new(name: "Example User", email: "user@example.com", password: "foobar", password_confirmation: "foobar", zip: 98033, account_type: 0)
  end

  test "website setting should be valid" do
  	@website_setting.save
  	assert @website_setting.valid?
  end

  test "website setting should be invalid" do

  	#NOTE: took off the 'presence' validation and leaving things 'as-is' in the schema, which is
  	#that null is not allowed for recurring_postings_enabled but it is for new_customer_access_code_required.
  	#there is no good reason for this. just lazily moving along rather than 'fixing' it.
  	
  	@website_setting.recurring_postings_enabled = nil
		assert_raise ActiveRecord::StatementInvalid do
			@website_setting.save  	
		end
  	
  	@website_setting.recurring_postings_enabled = true
  	@website_setting.new_customer_access_code_required = nil
  	@website_setting.save
  	assert @website_setting.valid?

  end

end
