require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  test "account_activation" do
    user = users(:c1)
    user.activation_token = User.new_token
    mail = UserMailer.account_activation(user)
    assert_equal "Account activation", mail.subject
    assert_equal [user.email], mail.to
    assert_equal ["david@farmerscellar.com"], mail.from
    assert_match user.name,               mail.body.encoded
    assert_match user.activation_token,   mail.body.encoded
    assert_match CGI::escape(user.email), mail.body.encoded
  end

  test "password_reset" do
    user = users(:c1)
    user.reset_token = User.new_token
    mail = UserMailer.password_reset(user)
    assert_equal "Password reset", mail.subject
    assert_equal [user.email], mail.to
    assert_equal ["david@farmerscellar.com"], mail.from
    assert_match user.reset_token,        mail.body.encoded
    assert_match CGI::escape(user.email), mail.body.encoded
  end

  test "delivery_notification" do

    user = users(:c1)
    dropsite = dropsites(:dropsite1)
    basil = postings(:postingf4basil)
    avocado = postings(:postingf4avocado)

    tote_items = []
    basil.tote_items.each do |ti|
      tote_items << ti
    end
    
    avocado.tote_items.each do |ti|
      tote_items << ti
    end

    #this actually is a little wonky because this toteitem doesn't belong to c1, it belongs to another user
    #but oh well, we're using it here to test the mailer
    tote_items[2].state = ToteItem.states[:NOTFILLED]

    mail = UserMailer.delivery_notification(user, dropsite, tote_items)

    assert_equal "Delivery notification", mail.subject
    assert_equal [user.email], mail.to
    assert_equal ["david@farmerscellar.com"], mail.from

    assert_match basil.unit_kind.name, mail.body.encoded
    assert_match basil.user.farm_name, mail.body.encoded

    assert_match avocado.unit_kind.name, mail.body.encoded
    assert_match avocado.user.farm_name, mail.body.encoded
    
  end

  test "should send one time authorization receipt" do

    user = users(:c1)
    user.tote_items.update_all(state: ToteItem.states[:AUTHORIZED])
    checkout = Checkout.new(token: "mytoken", amount: get_gross_tote(user.tote_items), client_ip: "127.0.0.1", response: "response bla bla bla response", is_rt: false)
    assert checkout.valid?
    assert checkout.save
    checkout.tote_items << user.tote_items

    authorization = Authorization.new(token: "mytoken",
      payer_id: "payid",
      amount: get_gross_tote(user.tote_items),
      correlation_id: "correlation_id",
      transaction_id: "transaction_id",
      payment_date: Time.zone.now,
      gross_amount: get_gross_tote(user.tote_items) - 5,
      response: "response bla bla bla",
      ack: "success"
      )
    authorization.checkouts << checkout
    assert authorization.valid?
    assert authorization.save    

    mail = UserMailer.authorization_receipt(user, authorization)

    assert_equal "Authorization receipt", mail.subject
    assert_equal [user.email], mail.to
    assert_equal ["david@farmerscellar.com"], mail.from

    assert_match "This is your Farmer's Cellar receipt for payment authorization", mail.body.encoded
    authorized_amount = get_gross_tote(checkout.tote_items)
    assert authorized_amount > 0
    assert_match number_to_currency(authorized_amount), mail.body.encoded
    assert_match "The total payment amount authorized is", mail.body.encoded
    assert_match "We'll email you again on each of the delivery dates listed above to let you know if product has been delivered for you or not.", mail.body.encoded    
   
  end

  test "should send reference transaction authorization receipt" do

    user = users(:c1)
    rtba = Rtba.new(token: "token", ba_id: "ba_id", active: true)
    rtba.user = user
    assert rtba.valid?
    assert rtba.save
    add_subscription_and_item_to_c1
    
    rtauthorization = Rtauthorization.new(rtba: rtba)
    rtauthorization.authorize_items_and_subscriptions(user.tote_items)   
    assert rtauthorization.valid?
    assert rtauthorization.save

    mail = UserMailer.authorization_receipt(user, rtauthorization, user.tote_items)

    assert_equal "Authorization receipt", mail.subject
    assert_equal [user.email], mail.to
    assert_equal ["david@farmerscellar.com"], mail.from

    assert_match "This is your Farmer's Cellar receipt for payment authorization", mail.body.encoded
    authorized_amount = get_gross_tote(user.tote_items)
    assert authorized_amount > 0
    assert_match number_to_currency(authorized_amount), mail.body.encoded
    assert_match "Additionally, you authorized future charges to your payment account associated with the following subscription", mail.body.encoded
    assert_match user.subscriptions.last.description, mail.body.encoded
    assert_match "We'll email you again on each of the delivery dates listed above to let you know if product has been delivered for you or not.", mail.body.encoded    

  end

  def add_subscription_and_item_to_c1
    posting_recurrence = posting_recurrences(:one)
    subscription = Subscription.new(frequency: 1, on: true, user: users(:c1), posting_recurrence: posting_recurrence, quantity: 2)
    subscription.save
    subscription.generate_next_tote_item
  end  

end