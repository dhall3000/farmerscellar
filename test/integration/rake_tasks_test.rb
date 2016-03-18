require 'test_helper'
require 'utility/rake_helper'

class RakeTasksTest < ActionDispatch::IntegrationTest

  def setup
    ActionMailer::Base.deliveries.clear    
    @posting_apples = postings(:postingf1apples)
    @posting_milk = postings(:postingf2milk)
  end

  test "nightly tasks should not change state or send emails" do

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

  end

  test "nightly tasks should change state or send emails" do
  end

  test "week end tasks should not change state or send emails" do
  end

  test "week end tasks should change state or send emails" do
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