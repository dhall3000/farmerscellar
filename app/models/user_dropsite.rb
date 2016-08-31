class UserDropsite < ApplicationRecord
  belongs_to :user
  belongs_to :dropsite
end