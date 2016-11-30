class CreditorOrder < ApplicationRecord
  has_many :creditor_order_postings
  has_many :postings, through: :creditor_order_postings

  belongs_to :creditor, class_name: "User", foreign_key: "creditor_id"
  has_one :creditor_obligation

  validates :delivery_date, :order_value_producer_net, presence: true
  validates :order_value_producer_net, numericality: {greater_than: 0}
  validates_presence_of :creditor, :postings

  def self.submit(creditor, delivery_date, postings, order_value_producer_net)

    if !all_postings_share_creditor?(postings, creditor)
      return nil
    end

    co = CreditorOrder.create(creditor: creditor, delivery_date: delivery_date, postings: postings, order_value_producer_net: order_value_producer_net)

    if co.valid?
      puts "CreditorOrder.submit: sending order for #{postings.count.to_s} posting(s) to #{creditor.get_business_interface.name}"
      ProducerNotificationsMailer.current_orders(creditor, postings).deliver_now
    else
      puts "CreditorOrder.submit: creation of new CreditorOrder object failed. New object is invalid. Errors: #{co.errors}"
    end

    return co

  end

  def self.all_postings_share_creditor?(postings, creditor)

    if postings.nil? || !postings.any?
      return true
    end

    postings.each do |posting|

      if posting.get_creditor != creditor
        return false
      end

    end

    return true

  end

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