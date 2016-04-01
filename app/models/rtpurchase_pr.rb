class RtpurchasePr < ActiveRecord::Base
  belongs_to :rtpurchase
  belongs_to :purchase_receivable
end
