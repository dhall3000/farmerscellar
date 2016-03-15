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

  	@postings = []
  	postings.each do |posting|  		
  	  if posting.total_quantity_authorized_or_committed > 0
  	  	@postings << posting
  	  end
  	end  	

  	if @postings.nil? || !@postings.any?
  	  return
  	end

    mail to: email, subject: "Current orders for upcoming deliveries"
  end

  def payment_invoice(email, producer, total, payment_payable_ids)

    @producer = producer
    @total = total
    @posting_infos = {}

    payment_payable_ids.each do |payment_payable_id|

      pp = PaymentPayable.find(payment_payable_id)

      pp.tote_items.each do |tote_item|

        if !@posting_infos.has_key?(tote_item.posting)
          @posting_infos[tote_item.posting] = {unit_count: 0, amount: 0, unit_price: 0, sub_total: 0}
        end

        producer_net_item = get_producer_net_item(tote_item)

        @posting_infos[tote_item.posting][:unit_count] += tote_item.quantity
        @posting_infos[tote_item.posting][:sub_total] = (@posting_infos[tote_item.posting][:sub_total] + producer_net_item).round(2)
        @posting_infos[tote_item.posting][:unit_price] = producer_net_item / tote_item.quantity

      end

    end

    mail to: email, subject: "Payment invoice"

  end

end