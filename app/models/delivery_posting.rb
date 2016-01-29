class DeliveryPosting < ActiveRecord::Base
  belongs_to :posting
  belongs_to :delivery
end
