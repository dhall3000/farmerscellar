class UserDropsite < ActiveRecord::Base
  belongs_to :user
  belongs_to :dropsite
end