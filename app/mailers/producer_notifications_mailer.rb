class ProducerNotificationsMailer < ApplicationMailer
  include ToteItemsHelper

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.producer_notifications_mailer.current_orders.subject
  #
  def current_orders(creditor, postings)

  	if postings.nil? || !postings.any?
  	  return
  	end

  	@posting_infos = {}
    @total = 0

    @business_interface = creditor.get_business_interface

    if !@business_interface
      #this is a major problem. order email didn't go out. admin needs to be notified
      AdminNotificationMailer.general_message("major problem. order email didn't go out.", "creditor id #{creditor.id.to_s}").deliver_now
      return
    end

    subject = "Current orders for upcoming deliveries"

    if @business_interface.order_email_accepted
      @email = @business_interface.order_email      
    else
      @email = "david@farmerscellar.com"
      subject = "admin action required: " + subject
    end

  	postings.each do |posting|

      committed_items = posting.tote_items.where(state: ToteItem.states[:COMMITTED])
  	  if committed_items.count < 1
        next
      end

      unit_count = 0      

      committed_items.each do |tote_item|
        unit_count = unit_count + tote_item.quantity
      end

      if posting.units_per_case.nil? || posting.units_per_case < 2
        case_count = nil
      else
        case_count = unit_count / posting.units_per_case
        unit_count = case_count * posting.units_per_case 
      end

      sub_total = 0
      producer_net_unit = posting.get_producer_net_unit
      unit_count.times do
        sub_total = (sub_total + producer_net_unit).round(2)
      end

      @total = (@total + sub_total).round(2)
      @posting_infos[posting] = {unit_count: unit_count, case_count: case_count, sub_total: sub_total}

  	end  	

  	if @posting_infos.nil? || !@posting_infos.any?
  	  return
  	end

    mail to: @email, subject: subject

  end

  def payment_invoice(creditor, payment, posting_infos)

    @business_interface = creditor.get_business_interface

    subject = "Payment receipt"

    if @business_interface.paypal_accepted
      @email = @business_interface.paypal_email
    else
      @email = "david@farmerscellar.com"
      subject = "admin action required: " + subject
    end
    
    @payment = payment
    @posting_infos = posting_infos

    mail to: @email, subject: subject

  end

end