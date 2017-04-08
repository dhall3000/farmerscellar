require 'authorization_helper'

class BulkBuyer < Authorizer

  def setup
    super
    @a1 = users(:a1)
  end

  def fill_tote_items(posting_id, fill_all)

    posting = Posting.find(posting_id)
    num_tote_items = posting.tote_items.count

    if fill_all
      num_to_fill = num_tote_items
    else
      num_to_fill = [num_tote_items - 3, 1].max
    end    

    num_tote_items_filled = 0
    total_quantity = 0

    posting.tote_items.each do |tote_item|
      if num_tote_items_filled < num_to_fill
        puts "tote_item id: #{tote_item.id}"          
        total_quantity = total_quantity + tote_item.quantity
        num_tote_items_filled = num_tote_items_filled + 1          
      end
    end
 
    fill_posting(posting, total_quantity)

  end

  def transition_authorized_tote_items_to_committed(customers)    

    num_authorized = ToteItem.where(state: ToteItem.states[:AUTHORIZED]).count

    #now change all the tote_items from AUTHORIZED to COMMITTED
    order_cutoffs = []
    ToteItem.where(state: ToteItem.states[:AUTHORIZED]).each do |tote_item|
      order_cutoffs << tote_item.posting.order_cutoff
    end

    order_cutoffs = order_cutoffs.uniq.sort
    current_time = Time.zone.now

    order_cutoffs.each do |order_cutoff|
      travel_to order_cutoff
      RakeHelper.do_hourly_tasks
    end

    travel_to current_time

    num_committed = ToteItem.where(state: ToteItem.states[:COMMITTED]).count

    assert_equal 0, ToteItem.where(state: ToteItem.states[:AUTHORIZED]).count
    assert_equal num_authorized, num_committed

  end

  #this only fills the toteitems for the given postings
  def simulate_order_filling_for_postings(postings, fill_all_tote_items, time_travel_to_delivery_dates = false)

    #now log in as an admin
    log_in_as(@a1)
    assert is_logged_in?

    postings.each do |posting|
      
      if time_travel_to_delivery_dates
        travel_to posting.delivery_date + 1
      end

      fill_tote_items(posting.id, fill_all_tote_items)

      if time_travel_to_delivery_dates
        travel_back
      end

    end

  end  

  def create_bulk_buy(customers, fill_all_tote_items)
    create_authorization_for_customers(customers)
    assert_equal 0, Posting.where(state: Posting.states[:COMMITMENTZONE]).count
    assert_equal 0, Posting.where(state: Posting.states[:CLOSED]).count
    transition_authorized_tote_items_to_committed(customers)
    postings = Posting.where(state: Posting.states[:COMMITMENTZONE])
    assert postings.count > 0

    time_travel_to_delivery_dates = true
    

    simulate_order_filling_for_postings(postings, fill_all_tote_items, time_travel_to_delivery_dates)

    #verify there are no authorized
    assert_equal 0, ToteItem.where(state: ToteItem.states[:AUTHORIZED]).count    
    #verify there are no committed
    assert_equal 0, ToteItem.where(state: ToteItem.states[:COMMITTED]).count
    #verify there are filled
    assert ToteItem.where(state: ToteItem.states[:FILLED]).count > 0

    prs = PurchaseReceivable.all.to_a
    pr = prs[0]
    puts "amount=#{pr.amount.to_s}"
    puts pr.users.last.name
    puts "number of tote_items: #{pr.tote_items.count.to_s}"
  end
end