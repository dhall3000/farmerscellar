# Preview all emails at http://localhost:3000/rails/mailers/user_mailer
class UserMailerPreview < ActionMailer::Preview
  include ToteItemsHelper

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/pickup_deadline_reminder
  def pickup_deadline_reminder
    user = User.find_by(email: "c1@c.com")

    user.tote_items.first.update(state: ToteItem.states[:FILLED], quantity_filled: user.tote_items.first.quantity)
    user.tote_items.second.update(state: ToteItem.states[:FILLED], quantity_filled: user.tote_items.second.quantity)
    user.tote_items.third.update(state: ToteItem.states[:FILLED], quantity_filled: 1)

    user.pickups.create

    UserMailer.pickup_deadline_reminder(user, user.tote_items)
  end

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

  #http://localhost:3000/rails/mailers/user_mailer/authorization_receipt_one_time
  def authorization_receipt_one_time
    
    user = User.find_by(email: "c1@c.com")
    posting = Posting.first
    #create tote items
    ti1 = ToteItem.new(quantity: 2, posting: posting, user: user, price: posting.price)
    ti1.save
    ti2 = ToteItem.new(quantity: 3, posting: posting, user: user, price: posting.price)
    ti2.save
    gross_amount = get_gross_tote([ti1, ti2])
    #create checkout
    checkout = Checkout.new(token: "fakeresponsetoken", amount: gross_amount, client_ip: "127.0.0.1", response: "fakeresponse", is_rt: false)
    #attach tote items to checkout
    checkout.tote_items << ti1
    checkout.tote_items << ti2
    #create authorization    
    authorization = Authorization.new(
      amount: gross_amount,
      token: "faketoken",
      payer_id: "fakepayerid",
      correlation_id: "correlation_id",
      transaction_id: "transaction_id",
      payment_date: Time.zone.now,
      gross_amount: gross_amount,
      response: "response",
      ack: "Success"
      )
    authorization.save
    authorization.checkouts << checkout
    authorization.save

    UserMailer.authorization_receipt(user, authorization)

  end

  #http://localhost:3000/rails/mailers/user_mailer/authorization_receipt_rt
  def authorization_receipt_rt

  end

  # Preview this email at
  # http://localhost:3000/rails/mailers/user_mailer/delivery_notification_partner_producer
  def delivery_notification_partner_producer

    email = "partner_user@p.com"

    user = User.find_by(email: email)

    if user.nil?

      user = User.new(
        email: email,
        password: "oxuntvZb{?c6193753cjapJ",
        name: "Bob Partner",
        account_type: User.types[:CUSTOMER],
        activated: true,
        partner_user: true
        )

      user.save
      user.set_dropsite(Dropsite.first)

    end

    dropsite = user.dropsite

    UserMailer.delivery_notification(user, dropsite, tote_items = nil, "Azure Standard")

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

  #Preview this email at
  #http://localhost:3000/rails/mailers/user_mailer/purchase_receipt_various_fill_states
  def purchase_receipt_various_fill_states

    user = User.find_by(email: "c1@c.com")
    if user.dropsite.nil?
      user.set_dropsite(Dropsite.first)
    end
    dropsite = user.dropsite
    tote_items = ToteItem.where(user_id: user.id)

    ti1 = tote_items[0]
    ti2 = tote_items[1]

    ti1.state = ToteItem.states[:COMMITTED]
    ti1.transition(:tote_item_filled, {quantity_filled: ti1.quantity})
    
    ti2.state = ToteItem.states[:COMMITTED]    
    ti2.transition(:tote_item_filled, {quantity_filled: ti2.quantity})
    ti2.quantity = tote_items[1].quantity + 1

    pr1 = ti1.purchase_receivables.last
    pr2 = ti2.purchase_receivables.last

    #if pr.kind == PurchaseReceivable.kind[:NORMAL] && pr.state == PurchaseReceivable.states[:COMPLETE]        
    pr1.kind = PurchaseReceivable.kind[:NORMAL]
    pr1.state = PurchaseReceivable.states[:COMPLETE]
    pr1.save

    pr2.kind = PurchaseReceivable.kind[:NORMAL]
    pr2.state = PurchaseReceivable.states[:COMPLETE]
    pr2.save

    UserMailer.purchase_receipt(user, [ti1, ti2])

  end

end
