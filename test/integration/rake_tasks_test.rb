require 'test_helper'
require 'utility/rake_helper'
require 'bulk_buy_helper'

class RakeTasksTest < BulkBuyer

  def setup
    super
    ActionMailer::Base.deliveries.clear    
    @posting_apples = postings(:postingf1apples)
    @posting_milk = postings(:postingf2milk)
    @p1 = postings(:p1)
    @p2 = postings(:p2)
    @p3 = postings(:p3)
    @p4 = postings(:p4)
    @c5 = users(:c5)
    @c6 = users(:c6)
    @c7 = users(:c7)
  end

  test "nightly tasks should not change state or send emails" do

    assert_equal 0, ToteItem.where(status: ToteItem.states[:FILLED]).count, "This test requires there be no FILLED tote items as a pre-condition."    

    ActionMailer::Base.deliveries.clear
    assert_equal 0, ActionMailer::Base.deliveries.count

    db_snapshot_before
    RakeHelper.do_nightly_tasks
    db_snapshot_after
    verify_db_snapshot_equal

    db_snapshot_before
    RakeHelper.do_nightly_tasks
    db_snapshot_after
    verify_db_snapshot_equal

    assert_equal 0, ActionMailer::Base.deliveries.count
    ActionMailer::Base.deliveries.clear

  end

  test "should skip customers who have additional deliveries further ahead in this week" do

    ActionMailer::Base.deliveries.clear
    assert_equal 0, ActionMailer::Base.deliveries.count

    #authorize a bunch of tote items
    customers = [@c5, @c6, @c7]
    postings = [postings(:p1), postings(:p2), postings(:p3), postings(:p4)]
    create_authorization_for_customers(customers)

    #verify authorization receipts emailed
    assert ActionMailer::Base.deliveries.count > 0
    ActionMailer::Base.deliveries.clear

    travel_to @p1.commitment_zone_start - 1.hour

    #loop over 10 days worth of minutes
    14400.times do

      top_of_hour = Time.zone.now.min == 0
      is_noon_hour = Time.zone.now.hour == 12

      #run hourly tasks at top of each hour. this will transition tote items to COMMITTED
      if top_of_hour

        ActionMailer::Base.deliveries.clear

        RakeHelper.do_hourly_tasks

        committed_tote_item_count = ToteItem.where(status: ToteItem.states[:COMMITTED]).count
        email_count = ActionMailer::Base.deliveries.count

        if email_count > 0
          current_order_mail = ActionMailer::Base.deliveries[1]
          commit_totes_mail = ActionMailer::Base.deliveries[0]
        end

        #this is the first of the postings to enter the commitment zone so there should only be items related to this
        #posting in the total committed tote item count
        if Time.zone.now == @p1.commitment_zone_start
          assert_equal 3, committed_tote_item_count          
          assert_equal 2, email_count          
          assert_appropriate_email(current_order_mail, @p1.user.email, "Current orders for upcoming deliveries", "Below are orders for your upcoming delivery")
          assert_appropriate_email(commit_totes_mail, "david@farmerscellar.com", "commit_totes job summary report", "number of tote_items transitioned from AUTHORIZED -> COMMITTED")
        elsif Time.zone.now == @p2.commitment_zone_start         
          #at the time we enter the commitment zone for posting p2 we won't have delivered the items for p1 yet
          #so the total committed tote item count should be all the items for postings p1 and p2        
          assert_equal 4, committed_tote_item_count
          assert_equal 2, email_count
          assert_appropriate_email(current_order_mail, @p2.user.email, "Current orders for upcoming deliveries", "Below are orders for your upcoming delivery")
          assert_appropriate_email(commit_totes_mail, "david@farmerscellar.com", "commit_totes job summary report", "number of tote_items transitioned from AUTHORIZED -> COMMITTED")
        elsif Time.zone.now == @p3.commitment_zone_start         
          #by the time we get to p3's commitment zone, p1's items should have been tranitioned out of the COMMITTED state
          #so they no longer contribute to the total committed tote item count. it's only p2 and p3 that contribute.        
          assert_equal 3, committed_tote_item_count
          assert_equal 2, email_count
          assert_appropriate_email(current_order_mail, @p3.user.email, "Current orders for upcoming deliveries", "Below are orders for your upcoming delivery")
          assert_appropriate_email(commit_totes_mail, "david@farmerscellar.com", "commit_totes job summary report", "number of tote_items transitioned from AUTHORIZED -> COMMITTED")
        elsif Time.zone.now == @p4.commitment_zone_start        
          #the weekend has elapsed since p3's delivery, so by the time we get to this monday - p4's delivery - all other
          #tote items should have transitioned out of the committed state        
          assert_equal 1, committed_tote_item_count
          assert_equal 2, email_count
          assert_appropriate_email(current_order_mail, @p4.user.email, "Current orders for upcoming deliveries", "Below are orders for your upcoming delivery")
          assert_appropriate_email(commit_totes_mail, "david@farmerscellar.com", "commit_totes job summary report", "number of tote_items transitioned from AUTHORIZED -> COMMITTED")
        else
          assert_equal 0, ActionMailer::Base.deliveries.count
        end

      end

      if is_noon_hour && top_of_hour

        #loop through postings and fill those for whom it presently is noon on their delivery date
        postings.each do |posting|

          is_delivery_date = Time.zone.now.midnight == posting.delivery_date

          if is_delivery_date

            ActionMailer::Base.deliveries.clear

            previous_filled_count = ToteItem.where(status: ToteItem.states[:FILLED]).count

            #ok, food arrived. now fill some orders        
            fill_all_tote_items = true            
            simulate_order_filling_for_postings([posting], fill_all_tote_items)
            assert previous_filled_count < ToteItem.where(status: ToteItem.states[:FILLED]).count            

            assert_equal 0, ActionMailer::Base.deliveries.count

          end
          
        end

      end

      #purchase receipts and bulk purchase admin reports

      #run the nightly tasks at 10pm pst. this will process bulk purchases
      if Time.zone.now.hour == 22 && top_of_hour

        ActionMailer::Base.deliveries.clear
        RakeHelper.do_nightly_tasks     
        emails = ActionMailer::Base.deliveries

        #this is after the nightly tasks on the Monday delivery
        if Time.zone.now.midnight == @p1.delivery_date
          assert_equal 1, PurchaseReceivable.count, "There should only be 1 PurchaseReceivable because the other two customers still have tote items to be delivered later on this week"
          assert_equal 2, ActionMailer::Base.deliveries.count
          assert_appropriate_email(emails[0], "c5@c.com", "Purchase receipt", "This email is your Farmer's Cellar purchase receipt")
          assert_appropriate_email(emails[1], "david@farmerscellar.com", "bulk purchase report", "BulkPurchase id: 1")
        end

        #this is after the nightly tasks on the Wednesday delivery
        if Time.zone.now.midnight == @p2.delivery_date
          assert_equal 1, PurchaseReceivable.count, "There should only be 2 PurchaseReceivables because there's another customer to have tote items delivered later on this week"
          assert_equal 0, ActionMailer::Base.deliveries.count
        end

        #this is after the nightly tasks on the Friday delivery
        if Time.zone.now.midnight == @p3.delivery_date
          assert_equal 3, PurchaseReceivable.count, "There should be 3 PurchaseReceivables because all three customers should have gotten purchases by now"
          assert_equal 3, ActionMailer::Base.deliveries.count
          assert_appropriate_email(emails[0], "c7@c.com", "Purchase receipt", "This email is your Farmer's Cellar purchase receipt")
          assert_appropriate_email(emails[1], "c6@c.com", "Purchase receipt", "This email is your Farmer's Cellar purchase receipt")          
          assert_appropriate_email(emails[2], "david@farmerscellar.com", "bulk purchase report", "BulkPurchase id: 2")
        end

        #this is after the nightly tasks on the 2nd Monday delivery
        if Time.zone.now.midnight == @p4.delivery_date
          assert_equal 4, PurchaseReceivable.count, "There should be a 4th PurchaseReceivable because we're in the next week now which is where c5's 2nd tote item is delivered"
          assert_equal 2, ActionMailer::Base.deliveries.count
          assert_appropriate_email(emails[0], "c5@c.com", "Purchase receipt", "This email is your Farmer's Cellar purchase receipt")
          assert_appropriate_email(emails[1], "david@farmerscellar.com", "bulk purchase report", "BulkPurchase id: 3")
        end

      end

      travel 1.minute
      
    end

    #there should be a bp on the first monday because that customer has no further deliveries that week
    #there should not be a bp on wednesday night because all filled customers have remaining deliveries later that week
    #there should be a bp on friday night because that's the last delivery this week for these two customers
    #there should be a bp on the 2nd monday because that customer has no more deliveries that week
    assert_equal 3, BulkPurchase.count

    #this bp represents only c5's 1st monday night's purchase
    assert_equal 8.67, BulkPurchase.all[0].gross
    #this bp represents all orders of c6 & c7 which occurred on friday night
    assert_equal 81.97, BulkPurchase.all[1].gross
    #this bp represents only c5's 2nd monday night's purchase
    assert_equal 46.89, BulkPurchase.all[2].gross

    #go back to regular time    
    travel_back    

  end

  test "nightly tasks should change state and send emails" do
    
    ActionMailer::Base.deliveries.clear
    assert_equal 0, ActionMailer::Base.deliveries.count

    #authorize a bunch of tote items
    customers = [@c1, @c2, @c3, @c4]    
    create_authorization_for_customers(customers)

    #verify authorization receipts emailed
    assert ActionMailer::Base.deliveries.count > 0
    ActionMailer::Base.deliveries.clear

    travel_to (@c1.tote_items[1].posting.commitment_zone_start - 1.hour)
    
    #now transition them to committed
    3.times do |i|
      RakeHelper.do_hourly_tasks
      #time travel 1 hour
      travel 1.hour      
    end

    #verify producer order notifications emailed
    assert ActionMailer::Base.deliveries.count > 0
    ActionMailer::Base.deliveries.clear

    #now time travel to delivery day
    travel_to @c1.tote_items[1].posting.delivery_date + 1.minute    

    #ok, food arrived. now fill some orders        
    fill_all_tote_items = true
    simulate_order_filling_for_postings(Posting.where("delivery_date < ?", Time.zone.now), fill_all_tote_items)    

    db_snapshot_before
    RakeHelper.do_nightly_tasks
    db_snapshot_after
    verify_db_snapshot_not_equal

    #assert ActionMailer::Base.deliveries.count > 0    
    ActionMailer::Base.deliveries.clear

    #go back to regular time    
    travel_back    

  end

  test "week end tasks should not change state or send emails" do
  end

  test "week end tasks should change state and send emails" do
  end

  test "hourly tasks should not change state or send emails" do
    #make sure no totes are authorized
    assert_equal 0, ToteItem.where(status: ToteItem.states[:AUTHORIZED]).count
    #save the state counts of all toteitems
    tote_items_set
    #run the task    
    RakeHelper.do_hourly_tasks
    #verify no state changed
    tote_items_compare_equal
    #verify no emails sent
    assert_equal 0, ActionMailer::Base.deliveries.count    
  end

  test "hourly tasks should change state and send emails" do

    #make sure some totes are authorized
    assert_equal 0, ToteItem.where(status: ToteItem.states[:AUTHORIZED]).count
    @posting_apples.tote_items.update_all(status: ToteItem.states[:AUTHORIZED])    
    @posting_milk.tote_items.update_all(status: ToteItem.states[:AUTHORIZED])
    authorized_tote_items_count = @posting_apples.tote_items.count + @posting_milk.tote_items.count
    assert_equal authorized_tote_items_count, ToteItem.where(status: ToteItem.states[:AUTHORIZED]).count
    
    #time travel to 65 minutes before commitment zone start time
    travel_to (@posting_apples.commitment_zone_start - 65.minutes)

    #now loop over the next 130 minutes
    130.times do |i|

      #time travel 1 minute
      travel 1.minute

      #save tote items' state for later comparison
      tote_items_set

      #run the task
      RakeHelper.do_hourly_tasks

      if Time.zone.now < @posting_apples.commitment_zone_start
        #before transition
        tote_items_compare_equal
        #verify no emails sent
        assert_equal 0, ActionMailer::Base.deliveries.count    
      elsif Time.zone.now == @posting_apples.commitment_zone_start
        #at transition

        #this is how many committed tote items we expect to see
        committed_count = @posting_apples.tote_items.count + @posting_milk.tote_items.count
        #verify that we have the proper amount of committed tote items
        assert_equal committed_count, ToteItem.where(status: ToteItem.states[:COMMITTED]).count        
        #now verify that the number of committed tote items actually changed on this 1 minute time travel
        assert_not_equal @committed_count, committed_count

        #verify the proper emails were sent
        assert_equal 3, ActionMailer::Base.deliveries.count        
        assert_equal "david@farmerscellar.com", ActionMailer::Base.deliveries[0].to[0]
        assert_equal "f2@f.com", ActionMailer::Base.deliveries[1].to[0]
        assert_equal "david@farmerscellar.com", ActionMailer::Base.deliveries[1].bcc[0]
        assert_equal "f1@f.com", ActionMailer::Base.deliveries[2].to[0]
        assert_equal "david@farmerscellar.com", ActionMailer::Base.deliveries[2].bcc[0]
        ActionMailer::Base.deliveries.clear    
      else         
        #after transition
        tote_items_compare_equal
        #verify no emails sent after the transition
        assert_equal 0, ActionMailer::Base.deliveries.count    
        #verify no tote items come in to the authorized state
        assert_equal 0, @authorized_count
        #this is how many committed tote items we expect to see
        committed_count = @posting_apples.tote_items.count + @posting_milk.tote_items.count
        #verify we have the proper amount of committed totes
        assert_equal @committed_count, committed_count
      end

    end

    #go back to regular time
    travel_back

  end

  def assert_appropriate_email(mail, to, subject, body)
    assert_equal subject, mail.subject
    assert_equal [to], mail.to
    assert_equal ["david@farmerscellar.com"], mail.from
    assert_match body, mail.body.encoded
  end

  def verify_db_snapshot_equal
    assert_equal "true", db_snapshot_equal
  end

  def verify_db_snapshot_not_equal
    assert db_snapshot_equal != "true"
  end

  def db_snapshot_equal

    if @db_snapshot_before[:num_tote_items_filled] != @db_snapshot_after[:num_tote_items_filled]
      return "@db_snapshot_before[:num_tote_items_filled] == " + @db_snapshot_before[:num_tote_items_filled].to_s + ", @db_snapshot_after[:num_tote_items_filled] == " + @db_snapshot_after[:num_tote_items_filled].to_s
    end

    if @db_snapshot_before[:num_tote_items_purchasepending] != @db_snapshot_after[:num_tote_items_purchasepending]
      return "@db_snapshot_before[:num_tote_items_purchasepending] == " + @db_snapshot_before[:num_tote_items_purchasepending].to_s + ", @db_snapshot_after[:num_tote_items_purchasepending] == " + @db_snapshot_after[:num_tote_items_purchasepending].to_s
    end

    if @db_snapshot_before[:num_purchase_receivables] != @db_snapshot_after[:num_purchase_receivables]
      return "@db_snapshot_before[:num_purchase_receivables] == " + @db_snapshot_before[:num_purchase_receivables].to_s + ", @db_snapshot_after[:num_purchase_receivables] == " + @db_snapshot_after[:num_purchase_receivables].to_s
    end

    if @db_snapshot_before[:num_purchases] != @db_snapshot_after[:num_purchases]
      return "@db_snapshot_before[:num_purchases] == " + @db_snapshot_before[:num_purchases].to_s + ", @db_snapshot_after[:num_purchases] == " + @db_snapshot_after[:num_purchases].to_s
    end

    if @db_snapshot_before[:num_bulk_buys] != @db_snapshot_after[:num_bulk_buys]
      return "@db_snapshot_before[:num_bulk_buys] == " + @db_snapshot_before[:num_bulk_buys].to_s + ", @db_snapshot_after[:num_bulk_buys] == " + @db_snapshot_after[:num_bulk_buys].to_s
    end

    if @db_snapshot_before[:num_bulk_purchases] != @db_snapshot_after[:num_bulk_purchases]
      return "@db_snapshot_before[:num_bulk_purchases] == " + @db_snapshot_before[:num_bulk_purchases].to_s + ", @db_snapshot_after[:num_bulk_purchases] == " + @db_snapshot_after[:num_bulk_purchases].to_s
    end
    
    return "true"

  end

  def db_snapshot_before
    @db_snapshot_before = db_snapshot
  end

  def db_snapshot_after
    @db_snapshot_after = db_snapshot
  end

  def db_snapshot

    db_snapshot = {}

    db_snapshot[:num_tote_items_filled] = ToteItem.where(status: ToteItem.states[:FILLED]).count
    db_snapshot[:num_tote_items_purchasepending] = ToteItem.where(status: ToteItem.states[:PURCHASEPENDING]).count
    db_snapshot[:num_purchase_receivables] = PurchaseReceivable.count
    db_snapshot[:num_purchases] = Purchase.count
    db_snapshot[:num_bulk_buys] = BulkBuy.count
    db_snapshot[:num_bulk_purchases] = BulkPurchase.count

    return db_snapshot

  end

  def tote_items_set
    #{ADDED: 0, AUTHORIZED: 1, COMMITTED: 2, FILLPENDING: 3, FILLED: 4, NOTFILLED: 5, REMOVED: 6, PURCHASEPENDING: 7, PURCHASED: 8, PURCHASEFAILED: 9}
    @added_count = ToteItem.where(status: ToteItem.states[:ADDED]).count
    @authorized_count = ToteItem.where(status: ToteItem.states[:AUTHORIZED]).count
    @committed_count = ToteItem.where(status: ToteItem.states[:COMMITTED]).count
    @fillpending_count = ToteItem.where(status: ToteItem.states[:FILLPENDING]).count
    @filled_count = ToteItem.where(status: ToteItem.states[:FILLED]).count
    @notfilled_count = ToteItem.where(status: ToteItem.states[:NOTFILLED]).count
    @removed_count = ToteItem.where(status: ToteItem.states[:REMOVED]).count
    @purchasepending_count = ToteItem.where(status: ToteItem.states[:PURCHASEPENDING]).count
    @purchased_count = ToteItem.where(status: ToteItem.states[:PURCHASED]).count
    @purchasefailed_count = ToteItem.where(status: ToteItem.states[:PURCHASEFAILED]).count
  end

  def tote_items_compare_equal
    assert_equal @added_count, ToteItem.where(status: ToteItem.states[:ADDED]).count
    assert_equal @authorized_count, ToteItem.where(status: ToteItem.states[:AUTHORIZED]).count
    assert_equal @committed_count, ToteItem.where(status: ToteItem.states[:COMMITTED]).count
    assert_equal @fillpending_count, ToteItem.where(status: ToteItem.states[:FILLPENDING]).count
    assert_equal @filled_count, ToteItem.where(status: ToteItem.states[:FILLED]).count
    assert_equal @notfilled_count, ToteItem.where(status: ToteItem.states[:NOTFILLED]).count
    assert_equal @removed_count, ToteItem.where(status: ToteItem.states[:REMOVED]).count
    assert_equal @purchasepending_count, ToteItem.where(status: ToteItem.states[:PURCHASEPENDING]).count
    assert_equal @purchased_count, ToteItem.where(status: ToteItem.states[:PURCHASED]).count
    assert_equal @purchasefailed_count, ToteItem.where(status: ToteItem.states[:PURCHASEFAILED]).count
  end
end