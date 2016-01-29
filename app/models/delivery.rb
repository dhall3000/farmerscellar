class Delivery < ActiveRecord::Base
  has_many :delivery_postings
  has_many :postings, through: :delivery_postings

  has_many :delivery_dropsites
  has_many :dropsites, through: :delivery_dropsites
end
