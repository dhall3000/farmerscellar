# Preview all emails at http://localhost:3000/rails/mailers/producer_notifications_mailer
class ProducerNotificationsMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/producer_notifications_mailer/current_orders
  def current_orders
  	postings = Posting.all
    ToteItem.all.update_all(state: ToteItem.states[:COMMITTED])
  	creditor = postings.first.user.get_creditor
    ProducerNotificationsMailer.current_orders(creditor, postings)
  end

end
