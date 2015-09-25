class ProducerNotificationsMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.producer_notifications_mailer.current_orders.subject
  #
  def current_orders(email, postings)

  	if postings.nil?
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
end
