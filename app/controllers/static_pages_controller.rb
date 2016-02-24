class StaticPagesController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin, only: [:test_page]
  before_action :redirect_to_root_if_not_logged_in, only: [:how_things_work]
  before_action :redirect_to_root_if_user_lacks_access, only: [:how_things_work]
  
  def home
    @website_settings = WebsiteSetting.last
  end

  def about
  end

  def contact
  end

  def how_things_work
  end

  def support    
  end

  def test_page
  end
end
