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

    tote_items[0].state = ToteItem.states[:PURCHASED]
    tote_items[1].state = ToteItem.states[:PURCHASEFAILED]

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

end