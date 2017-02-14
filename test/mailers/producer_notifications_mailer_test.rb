require 'test_helper'

class ProducerNotificationsMailerTest < ActionMailer::TestCase
  test "current_orders" do  	
  	tote_items = ToteItem.all
  	tote_items.update_all(state: ToteItem.states[:COMMITTED])
    ps = Posting.all.where(user: users(:f1))

    #ugh, there's some dumb invalid posting in this lot so strip it out
    ps_keep = []

    count = 0
    while count < ps.count
      if ps[count].valid?
        ps_keep << ps[count]
      end
      count += 1
    end

    ActionMailer::Base.deliveries.clear
    CreditorOrder.submit(ps_keep)
    assert_equal 1, ActionMailer::Base.deliveries.count
    mail = ActionMailer::Base.deliveries.last    

    assert_equal "Current orders for upcoming deliveries", mail.subject
    assert_equal [ps.first.user.email], mail.to
    assert_equal ["david@farmerscellar.com"], mail.from
    assert_match "Below are orders for your upcoming delivery", mail.body.encoded
  end

end