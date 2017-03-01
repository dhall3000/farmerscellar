require 'test_helper'

class ProducerNotificationsMailerTest < ActionMailer::TestCase
  test "current_orders" do  	
  	tote_items = ToteItem.all  	
    ps = Posting.all.where(user: users(:f1))
    customer = ps.first.tote_items.first.user
    create_one_time_authorization_for_customer(customer)
    ToteItem.all.update_all(state: ToteItem.states[:COMMITTED])

    #ugh, there's some dumb invalid posting in this lot so strip it out
    ps_keep = []

    count = 0
    while count < ps.count
      if ps[count].valid? && ps[count].inbound_order_value_producer_net > 0
        ps_keep << ps[count]
      end
      count += 1
    end

    ActionMailer::Base.deliveries.clear
    CreditorOrder.submit(ps_keep)
    assert_equal 1, ActionMailer::Base.deliveries.count
    mail = ActionMailer::Base.deliveries.last    

    subject = "Order for #{ps_keep.first.delivery_date.strftime("%A, %B")} #{ps_keep.first.delivery_date.day.ordinalize} delivery"
    assert_equal subject, mail.subject
    assert_equal [ps.first.user.email], mail.to
    assert_equal ["david@farmerscellar.com"], mail.from
    assert_match "Below are orders for your upcoming delivery", mail.body.encoded
  end

end