class Rtpurchase < ActiveRecord::Base
	has_many :rtpurchase_prs
	has_many :purchase_receivables, through: :rtpurchase_prs
end