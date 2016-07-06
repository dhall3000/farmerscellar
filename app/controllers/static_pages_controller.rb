class StaticPagesController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin, only: [:test_page, :test_exception]
  
  def home
    @website_settings = WebsiteSetting.order("website_settings.id").last
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

  #this 'm' is for 'mobile'. the idea is i can have anybody (e.g. Jason Meyering) hit this page in production
  #and they can read the text to me and this could help me diagnose why they're having display problems
  def m
  end

  #intentionally cause an exception here to test production monitoring handling of such
  def test_exception    
    x = nil
    x.test_exception
  end

end
