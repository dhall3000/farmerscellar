class ProducerNotificationsMailer < ApplicationMailer
  include ToteItemsHelper

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.producer_notifications_mailer.current_orders.subject
  #
  def current_orders(creditor_order)

    if creditor_order.nil?
      return
    end

  	if creditor_order.postings.nil? || !creditor_order.postings.any?
  	  return
  	end

  	@posting_infos = {}
    @total = 0

    @business_interface = creditor_order.business_interface

    if !@business_interface
      #this is a major problem. order email didn't go out. admin needs to be notified
      AdminNotificationMailer.general_message("major problem. order email didn't go out.", "creditor id #{creditor_order.creditor.id.to_s}").deliver_now
      return
    end

    subject = "Order for #{creditor_order.delivery_date.strftime("%A, %B")} #{creditor_order.delivery_date.day.ordinalize} delivery"

    if @business_interface.order_email
      @email = @business_interface.order_email      
    else
      @email = "david@farmerscellar.com"
      subject = "admin action required: " + subject
    end

    @column_product_id_code = false
    @column_cases = false

  	creditor_order.postings.each do |posting|

      committed_items = posting.tote_items.where(state: ToteItem.states[:COMMITTED])
  	  if committed_items.count < 1
        next
      end

      if !posting.product_id_code.nil? && !posting.product_id_code.empty?
        @column_product_id_code = true
      end

      unit_count = posting.inbound_num_units_ordered
      case_count = posting.inbound_num_cases_ordered

      if case_count && case_count > 0 && posting.units_per_case && posting.units_per_case > 1
        @column_cases = true
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

  def payment_receipt(creditor_order, payment)

    @creditor_order = creditor_order    

    subject = "Payment receipt"

    if @creditor_order.business_interface.payment_method?(:PAYPAL)
      @email = @creditor_order.business_interface.paypal_email    
    else
      @email = @creditor_order.business_interface.payment_receipt_email          
    end
    
    @payment = payment

    mail to: @email, subject: subject

  end

end