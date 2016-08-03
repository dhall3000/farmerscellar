class PickupsController < ApplicationController
	before_action :redirect_to_root_if_user_not_dropsite_user

  def new
    @is_dropsite_user = true
  end

  def create

    mockup_mode = false

    @is_dropsite_user = true
  	entered_code = params[:pickup_code]
  	@pickup_code = PickupCode.new(code: entered_code, user: current_user)

  	if @pickup_code.valid? || mockup_mode
  		@pickup_code = PickupCode.find_by(code: entered_code)  		
  		if @pickup_code.nil? && !mockup_mode
	  		flash.now[:danger] = "Invalid code entry"
	  		render 'pickups/new'	  	
  		else
        if mockup_mode
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

        if Rails.env.production?
          toggle_garage_door
        end
        
        flash.now[:success] = "Thanks for checking out!"
  		end
  	else
  		flash.now[:danger] = "Invalid code entry"
  		render 'pickups/new'
  	end

  end

  def done

    if Rails.env.production?
      toggle_garage_door
    end
    
    redirect_to new_pickup_path

  end

  private    

    def toggle_garage_door
      url =  "http://#{request.ip}:1984/client?command=door2"
      uri = URI(url)
      response = Net::HTTP.get(uri)
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