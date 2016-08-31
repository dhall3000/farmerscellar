class DeliveryDropsite < ApplicationRecord
  belongs_to :delivery
  belongs_to :dropsite
end
