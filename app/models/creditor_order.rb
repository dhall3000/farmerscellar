class CreditorOrder < ApplicationRecord
  has_many :creditor_order_postings
  has_many :postings, through: :creditor_order_postings

  belongs_to :creditor, class_name: "User", foreign_key: "creditor_id"
  has_one :creditor_obligation

  validates :delivery_date, :order_value_producer_net, presence: true
  validates :order_value_producer_net, numericality: {greater_than: 0}
  validates_presence_of :creditor, :postings

  #OPEN means this order has been submitted to the creditor and we're awaiting activity based off that order
  #CLOSED means no further activity is expected on this order, neither fills nor funds
  def self.state(key)
    states = {OPEN: 0, CLOSED: 1}
    return states[key]
  end

  def self.submit(creditor, delivery_date, postings, order_value_producer_net)

    if !all_postings_share_creditor?(postings, creditor)
      return nil
    end

    co = CreditorOrder.create(creditor: creditor, delivery_date: delivery_date, postings: postings, order_value_producer_net: order_value_producer_net, state: CreditorOrder.state(:OPEN))

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

  def balanced?
    return creditor_obligation.nil? || creditor_obligation.balanced?
  end

  def add_payment(payment)

    if creditor_obligation.nil?      
      create_creditor_obligation
    end

    creditor_obligation.add_payment(payment)

  end

  def add_payment_payable(payment_payable)

    if creditor_obligation.nil?      
      create_creditor_obligation
    end

    creditor_obligation.add_payment_payable(payment_payable)

  end

  def transition(input)

    case state
      when CreditorOrder.state(:OPEN)
        case input
          when :value_exchanged_hands
            if creditor_obligation.balance == 0
              update(state: CreditorOrder.state(:CLOSED))              
            end
            return
        end
        return

      when CreditorOrder.state(:CLOSED)
        case input
          when :value_exchanged_hands
            if creditor_obligation.balance != 0
              update(state: CreditorOrder.state(:OPEN))              
            end
            return
        end
        return
    end

  end

  def state?(key)
    return state == CreditorOrder.state(key)
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

end