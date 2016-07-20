# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/account_activation
  def account_activation
    user = User.first
    user.activation_token = User.new_token
    UserMailer.account_activation(user)
  end

  # Preview this email at
  # http://localhost:3000/rails/mailers/user_mailer/password_reset
  def password_reset
    user = User.first
    user.reset_token = User.new_token
    UserMailer.password_reset(user)
  end

  # Preview this email at
  # http://localhost:3000/rails/mailers/user_mailer/authorization_receipt
  #NOTE: when i created this i had to modify the seeds file to change all the AUTHORIZED toteitems to be ADDED.
  #then i had to use the browser to execute an authorization to get all the db info associated properly for this to work
  def authorization_receipt
    user = User.find_by(email: "c1@c.com")
    authorization = user.tote_items.last.checkouts.last.authorizations.last    
    UserMailer.authorization_receipt(user, authorization)
  end

  # Preview this email at
  # http://localhost:3000/rails/mailers/user_mailer/delivery_notification
  def delivery_notification_unknown_state
    user = User.find_by(email: "c1@c.com")
    dropsite = user.dropsite
    tote_items = ToteItem.where(user_id: user.id)

    tote_items[0].state = ToteItem.states[:AUTHORIZED]
    tote_items[1].state = ToteItem.states[:AUTHORIZED]
    tote_items[2].state = ToteItem.states[:AUTHORIZED]

    UserMailer.delivery_notification(user, dropsite, tote_items)

  end

  #Preview this email at
  #http://localhost:3000/rails/mailers/user_mailer/delivery_notification_all_fully_filled
  def delivery_notification_all_fully_filled
    user = User.find_by(email: "c1@c.com")
    if user.dropsite.nil?
      user.set_dropsite(Dropsite.first)
    end
    dropsite = user.dropsite
    tote_items = ToteItem.where(user_id: user.id)

    tote_items.each do |ti|
      ti.state = ToteItem.states[:FILLED]
      ti.quantity_filled = ti.quantity
    end

    UserMailer.delivery_notification(user, dropsite, tote_items)
  end

  #Preview this email at
  #http://localhost:3000/rails/mailers/user_mailer/delivery_notification_various_fill_states
  def delivery_notification_various_fill_states
    user = User.find_by(email: "c1@c.com")
    if user.dropsite.nil?
      user.set_dropsite(Dropsite.first)
    end
    dropsite = user.dropsite
    tote_items = ToteItem.where(user_id: user.id)

    tote_items[0].state = ToteItem.states[:FILLED]
    tote_items[0].quantity_filled = tote_items[0].quantity

    tote_items[1].state = ToteItem.states[:FILLED]
    tote_items[1].quantity_filled = tote_items[1].quantity
    tote_items[1].quantity = tote_items[1].quantity + 1

    tote_items[2].state = ToteItem.states[:NOTFILLED]

    UserMailer.delivery_notification(user, dropsite, tote_items)
  end

end
