class CreditorOrder < ApplicationRecord
  has_many :creditor_order_postings
  has_many :postings, through: :creditor_order_postings

  belongs_to :creditor, class_name: "User", foreign_key: "creditor_id"
  has_one :creditor_obligation

  validates :delivery_date, :order_value_producer_net, presence: true
  validates :order_value_producer_net, numericality: {greater_than: 0}
  validates_presence_of :creditor, :postings

  def all_postings_closed?

    if postings.nil? || !postings.any?
      return true
    end

    postings.each do |posting|
      if !posting.state?(:CLOSED)
        return false
      end
    end

    return true

  end

  def add_posting(posting)
    ovpn = self.order_value_producer_net
    ovpn = (ovpn + posting.outbound_order_value_producer_net).round(2)
    update(order_value_producer_net: ovpn)
  end

end