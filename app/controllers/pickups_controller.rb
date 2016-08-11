class PickupsController < ApplicationController
	before_action :redirect_to_root_if_user_not_dropsite_user

  @@mockup_mode = false

  def new
    @is_dropsite_user = true
  end

  def create
    puts "PickupsController#create start"
    display_user_data
    puts "PickupsController#create end"
  end

  def toggle_garage_door

    puts "PickupsController.toggle_garage_door start"

    if Rails.env.production?

      http = Net::HTTP.new(request.ip, 1984)
      http.open_timeout = 10
      http.read_timeout = 10
      response = nil
      flash_message = "If the garage door isn't working please knock on the front door for help."

      begin
        response = http.get("/client?command=door2")
      rescue Net::ReadTimeout => e1
        flash.now[:danger] = flash_message
        puts "PickupsController.toggle_garage_door timeout. e1.message = #{e1.message}"
      rescue Net::OpenTimeout => e2
        flash.now[:danger] = flash_message
        puts "PickupsController.toggle_garage_door timeout. e2.message = #{e2.message}"
      end

      if response
        puts "PickupsController.toggle_garage_door response: #{response.class.to_s}"
      else
        puts "PickupsController.toggle_garage_door response is nil"
      end      

    end

    display_user_data(create_pickup_on_success = false)
    puts "PickupsController.toggle_garage_door end"    

  end

  private    

    def display_user_data(create_pickup_on_success = true)

      @mockup_mode = @@mockup_mode

      today_open = Time.zone.now.midnight + 8.hours
      today_close = today_open + 12.hours
      @closed = Time.zone.now < today_open || Time.zone.now > today_close

      @is_dropsite_user = true
      @pickup_code = params[:pickup_code]
      puts "PickupsController#display_user_data @pickup_code: #{@pickup_code.to_s}"
      @pickup_code = PickupCode.new(code: @pickup_code, user: current_user)

      if @pickup_code.valid? || @mockup_mode
        @pickup_code = PickupCode.find_by(code: @pickup_code.code)     
        if @pickup_code.nil? && !@mockup_mode
          flash.now[:danger] = "Invalid code entry"
          puts "PickupsController#display_user_data Invalid code entry: #{@pickup_code.to_s}"
          render 'pickups/new'      
        else

          puts "PickupsController#display_user_data valid code. Now fetching user and tote items..."

          if @mockup_mode
            @user = User.find_by(email: "c1@c.com")
            @tote_items = get_fake_tote_items(@user)
            create_fake_last_pickup(@user)
          else
            @user = @pickup_code.user
            #get a product list of everything that's been delivered since the last pickup (or 7 days, whichever is more recent)
            @tote_items = @user.tote_items_to_pickup                  
          end

          @last_pickup = @user.pickups.order("pickups.id").last
          #now create a new pickup to represent the current pickup                  

          if create_pickup_on_success
            @user.pickups.create
          end
          
          render 'pickups/create'

        end
      else
        flash.now[:danger] = "Invalid code entry"
        render 'pickups/new'
      end

    end

	  def redirect_to_root_if_user_not_dropsite_user
	    if !logged_in? || !current_user.account_type_is?(:DROPSITE)
	      redirect_to(root_url)
	    end
	  end

    def get_fake_tote_items(user)

      tote_items = []

      posting = Posting.first
      tote_items << ToteItem.new(quantity: 5, quantity_filled: 5, price: posting.price, posting: posting, user: user, state: ToteItem.states[:FILLED])

      posting = Posting.second
      tote_items << ToteItem.new(quantity: 5, quantity_filled: 3, price: posting.price, posting: posting, user: user, state: ToteItem.states[:FILLED])

      posting = Posting.third
      tote_items << ToteItem.new(quantity: 5, quantity_filled: 5, price: posting.price, posting: posting, user: user, state: ToteItem.states[:FILLED])

      posting = Posting.fourth
      tote_items << ToteItem.new(quantity: 5, price: posting.price, posting: posting, user: user, state: ToteItem.states[:NOTFILLED])

      return tote_items

    end

    def create_fake_last_pickup(user)
      pickup = user.pickups.create
      pickup.update(created_at: Time.zone.now - 7.days)
    end

end