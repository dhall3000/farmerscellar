class Capture < ActiveRecord::Base
  has_many :tote_item_captures
  has_many :tote_items, through: :tote_item_captures
  belongs_to :admin, class_name: "User", foreign_key: "admin_id"

  def self.states
  	{INITIATED: 0, COMPLETED: 1}
  end

  #TODO: admin must be set and it must be an admin. keywords = validates validation
  
end
