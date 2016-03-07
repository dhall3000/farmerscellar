require 'test_helper'
require 'utility/rake_helper'

class RakeTasksTest < ActionDispatch::IntegrationTest

  def setup
    ActionMailer::Base.deliveries.clear    
    @posting_apples = postings(:postingf1apples)
    @posting_milk = postings(:postingf2milk)
  end

  test "commit totes should not change state or send emails" do
    #make sure no totes are authorized
    assert_equal 0, ToteItem.where(status: ToteItem.states[:AUTHORIZED]).count
    #save the state counts of all toteitems
    tote_items_set
    #run the task    
    RakeHelper.commit_totes
    #verify no state changed
    tote_items_compare_equal
    #verify no emails sent
    assert_equal 0, ActionMailer::Base.deliveries.count    
  end

  test "commit totes should change state and send emails" do
    #make sure some totes are authorized
    assert_equal 0, ToteItem.where(status: ToteItem.states[:AUTHORIZED]).count
    @posting_apples.tote_items.update_all(status: ToteItem.states[:AUTHORIZED])    
    @posting_milk.tote_items.update_all(status: ToteItem.states[:AUTHORIZED])
    authorized_tote_items_count = @posting_apples.tote_items.count + @posting_milk.tote_items.count
    assert_equal authorized_tote_items_count, ToteItem.where(status: ToteItem.states[:AUTHORIZED]).count
    
    #time travel to 1 hour before commitment zone start time
    travel_to (@posting_apples.commitment_zone_start - 60.minutes)

    #now loop over the next 2 hours
    120.times do |i|

      #time travel 1 minute
      travel 1.minute

      #save tote items' state for later comparison
      tote_items_set

      #run the task
      RakeHelper.commit_totes

      if Time.zone.now == @posting_apples.commitment_zone_start

      else
        tote_items_compare_equal
      end

    end

    #verify state changed
    #verify no emails sent    

  end

  def tote_items_set
    #{ADDED: 0, AUTHORIZED: 1, COMMITTED: 2, FILLPENDING: 3, FILLED: 4, NOTFILLED: 5, REMOVED: 6, PURCHASEPENDING: 7, PURCHASED: 8, PURCHASEFAILED: 9}
    @added_count = ToteItem.where(status: ToteItem.states[:ADDED])
    @authorized_count = ToteItem.where(status: ToteItem.states[:AUTHORIZED])
    @committed_count = ToteItem.where(status: ToteItem.states[:COMMITTED])
    @fillpending_count = ToteItem.where(status: ToteItem.states[:FILLPENDING])
    @filled_count = ToteItem.where(status: ToteItem.states[:FILLED])
    @notfilled_count = ToteItem.where(status: ToteItem.states[:NOTFILLED])
    @removed_count = ToteItem.where(status: ToteItem.states[:REMOVED])
    @purchasepending_count = ToteItem.where(status: ToteItem.states[:PURCHASEPENDING])
    @purchased_count = ToteItem.where(status: ToteItem.states[:PURCHASED])
    @purchasefailed_count = ToteItem.where(status: ToteItem.states[:PURCHASEFAILED])
  end

  def tote_items_compare_equal
    assert_equal @added_count, ToteItem.where(status: ToteItem.states[:ADDED])
    assert_equal @authorized_count, ToteItem.where(status: ToteItem.states[:AUTHORIZED])
    assert_equal @committed_count, ToteItem.where(status: ToteItem.states[:COMMITTED])
    assert_equal @fillpending_count, ToteItem.where(status: ToteItem.states[:FILLPENDING])
    assert_equal @filled_count, ToteItem.where(status: ToteItem.states[:FILLED])
    assert_equal @notfilled_count, ToteItem.where(status: ToteItem.states[:NOTFILLED])
    assert_equal @removed_count, ToteItem.where(status: ToteItem.states[:REMOVED])
    assert_equal @purchasepending_count, ToteItem.where(status: ToteItem.states[:PURCHASEPENDING])
    assert_equal @purchased_count, ToteItem.where(status: ToteItem.states[:PURCHASED])
    assert_equal @purchasefailed_count, ToteItem.where(status: ToteItem.states[:PURCHASEFAILED])
  end
end