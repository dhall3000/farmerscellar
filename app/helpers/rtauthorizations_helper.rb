module RtauthorizationsHelper

	class FakeDetailsFor

		@success = true

	  def initialize(type)

	  	case type
	  	when "success"
	  		@success = true
	  	when "failure"
	  		@success = false
	  	end    

	  end
	  
	  def success?
	  	@success
	  end

	end

end

