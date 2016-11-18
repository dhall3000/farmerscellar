class AdminNotificationMailer < ApplicationMailer

  def general_message(subject, body, body_lines = nil)  	
    @body = body
    @body_lines = body_lines
    mail to: "david@farmerscellar.com", subject: subject
  end

  def receiving(postings_by_creditor, delivery_date)

    if postings_by_creditor.nil?
      return
    end

    @postings_by_creditor = postings_by_creditor
        
    mail to: "david@farmerscellar.com", subject: "postings receivable"

  end

end