require 'test_helper'

class ProducerNotificationsMailerTest < ActionMailer::TestCase
  test "current_orders" do  	
  	tote_items = ToteItem.all
  	tote_items.update_all(status: ToteItem.states[:COMMITTED])
  	ps = Posting.all
    mail = ProducerNotificationsMailer.current_orders(ps.first.user.email, ps).deliver_now

    assert_equal "Current orders for upcoming deliveries", mail.subject
    assert_equal [ps.first.user.email], mail.to
    assert_equal ["david@farmerscellar.com"], mail.from
    assert_match "Below are orders for your upcoming delivery", mail.body.encoded
  end

end