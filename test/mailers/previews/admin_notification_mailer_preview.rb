# Preview all emails at http://localhost:3000/rails/mailers/admin_notification_mailer
class AdminNotificationMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/admin_notification_mailer/commit_totes
  def commit_totes
    AdminNotificationMailer.commit_totes
  end

end
