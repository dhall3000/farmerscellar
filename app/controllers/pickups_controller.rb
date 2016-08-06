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
            
      url =  "http://#{request.ip}:1984/client?command=door2"
      uri = URI(url)
      response = Net::HTTP.get_response(uri)

      puts "PickupsController.toggle_garage_door response: #{response.class.to_a}"
      
    end

    display_user_data
    puts "PickupsController.toggle_garage_door end"    

  end

  private    

    def display_user_data

      @is_dropsite_user = true
      @pickup_code = params[:pickup_code]
      puts "PickupsController#create @pickup_code: #{@pickup_code.to_s}"
      @pickup_code = PickupCode.new(code: @pickup_code, user: current_user)

      if @pickup_code.valid? || @@mockup_mode
        @pickup_code = PickupCode.find_by(code: @pickup_code.code)     
        if @pickup_code.nil? && !@@mockup_mode
          flash.now[:danger] = "Invalid code entry"
          puts "PickupsController#create Invalid code entry: #{@pickup_code.to_s}"
          render 'pickups/new'      
        else

          puts "PickupsController#create valid code. Now fetching user and tote items..."

          if @@mockup_mode
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
          @user.pickups.create
          
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