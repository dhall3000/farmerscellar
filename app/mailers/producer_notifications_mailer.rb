class ProducerNotificationsMailer < ApplicationMailer
  include ToteItemsHelper

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.producer_notifications_mailer.current_orders.subject
  #
  def current_orders(email, postings)

  	if postings.nil? || !postings.any?
  	  return
  	end

  	@posting_infos = {}
    @total = 0

  	postings.each do |posting|  		

      if posting.user.email != email
        next
      end

      committed_items = posting.tote_items.where(state: ToteItem.states[:COMMITTED])
  	  if committed_items.count < 1
        next
      end

      unit_count = 0
      sub_total = 0

      committed_items.each do |tote_item|
        unit_count = unit_count + tote_item.quantity
        sub_total = (sub_total + get_producer_net_item(tote_item)).round(2)        
      end

      @total = (@total + sub_total).round(2)

      unit_price = (sub_total / unit_count.to_f).round(2)
      @posting_infos[posting] = {unit_price: unit_price, unit_count: unit_count, sub_total: sub_total}
  	  
  	end  	

  	if @posting_infos.nil? || !@posting_infos.any?
  	  return
  	end

    mail to: email, subject: "Current orders for upcoming deliveries"

  end

  def payment_invoice(producer, total, posting_infos)

    @producer = producer
    @total = total
    @posting_infos = posting_infos

    mail to: producer.email, subject: "Payment invoice"

  end

end