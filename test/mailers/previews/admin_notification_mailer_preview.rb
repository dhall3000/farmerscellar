# Preview all emails at http://localhost:3000/rails/mailers/admin_notification_mailer
class AdminNotificationMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/admin_notification_mailer/general_message
  def general_message
    AdminNotificationMailer.general_message("my subject", "my body")
  end

end
