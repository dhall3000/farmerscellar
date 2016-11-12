class CreditorOrder < ApplicationRecord
  has_many :creditor_order_postings
  has_many :postings, through: :creditor_order_postings
  
  belongs_to :creditor, class_name: "User", foreign_key: "creditor_id"

  validates :delivery_date, presence: true
  validates_presence_of :creditor, :postings
end