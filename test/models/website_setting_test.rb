require 'test_helper'

class WebsiteSettingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  def setup
  	@website_setting = WebsiteSetting.new(new_customer_access_code_required: true)
  end

  test "" do
  end

end
