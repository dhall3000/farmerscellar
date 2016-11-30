class Rtba < ApplicationRecord
  attr_accessor :test_params

  belongs_to :user
  has_many :rtauthorizations

  validates_presence_of :user
  validates :token, :ba_id, presence: true

  #'valid' means we've verified with paypal that the ba is still intact / legit  
  def ba_valid?

    if !active
      return false
    end

    if USEGATEWAY
      agreement_details = GATEWAY.agreement_details(ba_id, {})
    else
      if test_params && test_params == "failure"
        agreement_details = FakeAgreementDetails.new("failure")
      else
        agreement_details = FakeAgreementDetails.new("success")
      end
    end    

    if !agreement_details || !agreement_details.params || agreement_details.params["billing_agreement_status"] != "Active"
      deactivate
      reload
    end

    return active

  end

  #this method is tested by this:
  #test "should deauthorize rtauthorizations when paypal says billing agreement is inactive" do
  def deactivate

    #if we're already marked as inactive on our end there's nothing to do
    if !active
      return
    end
    
    update(active: false)
    deauthorize_rtauthorizations
    
  end

  private

    def deauthorize_rtauthorizations
    	rtauthorizations.each do |rta|
    		rta.deauthorize
    	end
    end

end

class FakeAgreementDetails
  attr_reader :params

  def initialize(type)
    case type
    when "success"
      @params = {
        "billing_agreement_status": "Active"
      }
    when "failure"
      @params = {
        "billing_agreement_status": nil
      }
    end

    @params = @params.stringify_keys

  end
  
end