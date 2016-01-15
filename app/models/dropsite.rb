class Dropsite < ActiveRecord::Base
  has_many :user_dropsites
  has_many :users, through: :user_dropsites
end