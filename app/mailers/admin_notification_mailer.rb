class AdminNotificationMailer < ApplicationMailer

  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.admin_notification_mailer.commit_totes.subject
  #
  def general_message(subject, body, body_lines = nil)  	
    @body = body
    @body_lines = body_lines
    mail to: "david@farmerscellar.com", subject: subject
  end
end
