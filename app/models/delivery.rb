class Delivery < ActiveRecord::Base
  belongs_to :posting
  has_many :tote_items
end