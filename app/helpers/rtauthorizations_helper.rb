module RtauthorizationsHelper

	class FakeSuccessMethod

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

	class FakeDetailsFor < FakeSuccessMethod

	end

	class FakeStore < FakeSuccessMethod
		attr_reader :authorization

		def initialize(type)
			super(type)
			@authorization = "fakebillingagreementid"
		end

	end

end

