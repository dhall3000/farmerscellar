class Posting < ActiveRecord::Base
  belongs_to :user
  belongs_to :product
  belongs_to :unit_category
  belongs_to :unit_kind

  validates :quantity_available, presence: true, numericality: { only_integer: true }

end
