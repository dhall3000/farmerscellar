class StaticPagesController < ApplicationController
  before_action :redirect_to_root_if_user_not_admin, only: [:test_page, :test_exception, :toggle_garage_door]

  def survey    
  end

  def news
    @update_time = PageUpdate.get_update_time("News")    
  end
  
  def home
    @website_settings = WebsiteSetting.order("website_settings.id").last

    @food_categories = nil    

    root_food_category = FoodCategory.includes(children: :uploads).where(parent: nil).first
    if root_food_category
      @food_categories = root_food_category.children.order(:sequence).joins(:uploads).distinct
    end
    
  end

  def about
  end

  def contact
  end

  def how_things_work    
    @update_time = PageUpdate.get_update_time("HowThingsWork")
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

  def toggle_garage_door
    puts "StaticPagesController.toggle_garage_door start"

    if Rails.env.production?

      http = Net::HTTP.new(Dropsite.first.ip_address, 1984)
      http.open_timeout = 10
      http.read_timeout = 10
      response = nil
      flash_message = "If the garage door isn't working please knock on the front door for help."

      begin
        response = http.get("/client?command=door2")
      rescue Net::ReadTimeout => e1
        flash.now[:danger] = flash_message
        puts "StaticPagesController.toggle_garage_door timeout. e1.message = #{e1.message}"
      rescue Net::OpenTimeout => e2
        flash.now[:danger] = flash_message
        puts "StaticPagesController.toggle_garage_door timeout. e2.message = #{e2.message}"
      end

      if response
        puts "StaticPagesController.toggle_garage_door response: #{response.class.to_s}"
      else
        puts "StaticPagesController.toggle_garage_door response is nil"
      end      

    end

    puts "StaticPagesController.toggle_garage_door end"    
    redirect_to root_path

  end

end