class Rtba < ActiveRecord::Base
  belongs_to :user
  has_many :rtauthorizations

  validates_presence_of :user
  validates :token, :ba_id, presence: true

  #'valid' means we've verified with paypal that the ba is still intact / legit
  def ba_valid?

  	#TODO:implement
    #if !active
    #return false

    #if !valid
      #active = false

    #return active
  	return true

  end

  def deactivate

    #if we're already marked as inactive on our end there's nothing to do
    if !active
      return
    end
    
    #TODO: cancel ba with pp
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
