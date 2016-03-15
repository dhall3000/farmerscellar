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

        retail_reduction_factor = 1.0 - 0.035 - get_commission_factor_tote([tote_item])

        @posting_infos[tote_item.posting][:unit_count] += tote_item.quantity
        @posting_infos[tote_item.posting][:sub_total] = (@posting_infos[tote_item.posting][:sub_total] + get_gross_item(tote_item) * retail_reduction_factor)
        @posting_infos[tote_item.posting][:unit_price] = (@posting_infos[tote_item.posting][:sub_total] / @posting_infos[tote_item.posting][:unit_count])

        x = 1

      end

    end

    @posting_infos.each do |posting, value|
      value[:sub_total] = value[:sub_total].round(2)
      value[:unit_price] = value[:unit_price].round(2)
    end

    mail to: email, subject: "Payment invoice"

  end

end