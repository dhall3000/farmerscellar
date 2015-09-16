class AdminNotificationMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.admin_notification_mailer.commit_totes.subject
  #
  def general_message(subject, body)  	
    @body = body
    mail to: "david@farmerscellar.com", subject: subject
  end
end
