require 'integration_helper'

class SiteLayoutTest < IntegrationHelper

  test "has proper layout links" do
  	get about_path
  	assert_template 'static_pages/about'
  	assert_select "a[href=?]", about_path, count: 1
  	assert_select "a[href=?]", root_path
  	assert_select "a[href=?]", contact_path
  end
  
end
