class PickupCode < ActiveRecord::Base
  belongs_to :user

  #we don't want to be too specific about what the proper code format is to discourage guessing
  validates :code, presence: true, format: { with: /\A[0-9]{4}\z/, message: "format is invalid" }
  validates_presence_of :user

  #finds and sets the code to a unique 4 digit random code that is unique for the given dropsite
  def set_code(dropsite)
 	
    if dropsite.nil?
      return
    end

    if dropsite.class.to_s != "Dropsite"
      return
    end

    if !dropsite.valid?
      return
    end

    count = 0

    #give 100 goes at trying to find a unique code. however, this is unique only an a per-dropsite basis
    while count < 100
    	
    	new_code = get_new_code(1000, 10000)
    	new_code = new_code.to_s

    	code_is_unique_to_this_dropsite = true

    	other_pickup_codes_with_this_value = PickupCode.where(code: new_code)

    	if other_pickup_codes_with_this_value.nil? || !other_pickup_codes_with_this_value.any?
    		break
    	end

	    other_pickup_codes_with_this_value.each do |other_pickup_code_with_this_value|

	    	if other_pickup_code_with_this_value.user.dropsite.id == dropsite.id
	    		code_is_unique_to_this_dropsite = false
	    		next
	    	end
	    	
	    end

	    if !code_is_unique_to_this_dropsite
	    	new_code = nil
	    end

	    if code_is_unique_to_this_dropsite || count > 100
	    	break
	    end

    	count += 1
    end

    if new_code.nil?
    	return
    end

    update(code: new_code)    

  end

  private

  	#provide integers greater equal zero, high_val > low_val
  	#low_val inclusive
  	#high_val exclusive
  	def get_new_code(low_val, high_val)

  		new_code = -1
  		
  		if low_val < 0
  			return new_code
  		end
  
  		if high_val <= low_val
  			return new_code
  		end

  		while new_code < 0
  			new_code = SecureRandom.random_number(high_val)
  			if new_code < low_val
  				new_code = -1
  			end
  		end

  		return new_code

  	end

end