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

  def payment_invoice(producer, total, posting_infos)

    @producer = producer
    @total = total
    @posting_infos = posting_infos

    mail to: producer.email, subject: "Payment invoice"

  end

end