class Dropsite < ActiveRecord::Base
	
  has_many :user_dropsites
  has_many :users, through: :user_dropsites

  has_many :delivery_dropsites
  has_many :deliveries, through: :delivery_dropsites

  validates :name, presence: true
  validates :hours, presence: true
  validates :address, presence: true
  validates :city, presence: true
  validates :state, presence: true, length: {minimum: 2, maximum: 2, message: " must be a 2 letter abbreviation"}
  validates :zip, presence: true, numericality: { only_integer: true, greater_than: 9999, less_than: 100000, message: " code invalid. Please enter a valid 5-digit zip code."}

end