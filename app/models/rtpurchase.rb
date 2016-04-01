class Rtpurchase < ActiveRecord::Base
	has_many :rtpurchase_prs
	has_many :purchase_receivables, through: :rtpurchase_prs

	validates_presence_of :purchase_receivables
	validates :message, :correlation_id, presence: true
end