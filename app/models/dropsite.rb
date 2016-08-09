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

  def last_food_clearout
    
    now = Time.zone.now
    days_back = now.wday
    
    if now.wday > 1
      days_back = days_back - 1
    elsif now.wday < 1
      days_back = days_back + 6
    else
      #ok, right now it is monday. is it before or after 8PM food sweep time?
      if now < (now.midnight + 20.hours)
        days_back = 7
      else
        days_back = 0
      end
    end

    last_dropsite_clearout_day = now - days_back.days
    last_dropsite_clearout_day_time = Time.zone.local(last_dropsite_clearout_day.year, last_dropsite_clearout_day.month, last_dropsite_clearout_day.day, 20, 0)

    return last_dropsite_clearout_day_time        

  end

end