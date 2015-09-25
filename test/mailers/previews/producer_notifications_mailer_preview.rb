# Preview all emails at http://localhost:3000/rails/mailers/producer_notifications_mailer
class ProducerNotificationsMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/producer_notifications_mailer/current_orders
  def current_orders
  	postings = Posting.all
  	email = postings.first.user.email
    ProducerNotificationsMailer.current_orders(email, postings)
  end

end
