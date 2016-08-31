class DeliveryPosting < ApplicationRecord
  belongs_to :posting
  belongs_to :delivery
end
