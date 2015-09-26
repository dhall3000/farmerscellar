require 'test_helper'
require 'authorization_helper'

class BulkBuyer < Authorizer

  def setup
    super
    @a1 = users(:a1)
  end

  def fill_tote_items(posting_id, fill_all)

    num_tote_items = Posting.find(posting_id).tote_items.count

    if fill_all
      num_to_fill = num_tote_items
    else
      num_to_fill = [num_tote_items - 3, 1].max
    end    

    num_tote_items_filled = 0
    
    while(num_tote_items_filled < num_to_fill)
      tote_item = assigns(:tote_item)
      if !tote_item.nil?
        puts "tote_item id: #{tote_item.id}"
        post tote_items_next_path, {tote_item: {id: tote_item.id, posting_id: posting_id}}
        num_tote_items_filled = num_tote_items_filled + 1
      end
    end      

  end

  def transition_authorized_tote_items_to_committed
    #verify tote_items are in the AUTHORIZED state
    assert_equal ToteItem.states[:AUTHORIZED], ToteItem.first.status    
    assert ToteItem.where(status: ToteItem.states[:ADDED]).count == 0
    assert ToteItem.where(status: ToteItem.states[:AUTHORIZED]).count > 0

    #now change all the tote_items from AUTHORIZED to COMMITTED
    ToteItem.where(status: ToteItem.states[:AUTHORIZED]).update_all(status: ToteItem.states[:COMMITTED])

    #now verify the tote_items are in the COMMITTED state as appropriate
    assert_equal ToteItem.states[:COMMITTED], ToteItem.first.status    
    assert ToteItem.where(status: ToteItem.states[:AUTHORIZED]).count == 0
    assert ToteItem.where(status: ToteItem.states[:COMMITTED]).count > 0
  end

  def simulate_order_filling(fill_all_tote_items)
    #now log in as an admin
    log_in_as(@a1)
    assert is_logged_in?

    get postings_path
    assert_template 'postings/index'
    postings = assigns(:postings)
    assert_not_nil postings
    puts "there are #{postings.count} postings"
    
    for posting in postings
      puts "posting_id: #{posting.id}"
      get tote_items_next_path(tote_item: {posting_id: posting.id})
      assert_template 'tote_items/next'
      fill_tote_items(posting.id, fill_all_tote_items)
      if !fill_all_tote_items
        post postings_no_more_product_path, posting_id: posting.id        
      end
    end
  end

  def create_bulk_buy(fill_all_tote_items)
    assert_equal 0, Authorization.count, "there should be no authorizations in the database at the beginning of this test but there actually are #{Authorization.count}"

    customers = [@c1, @c2, @c3, @c4]
    create_authorization_for_customers(customers)
    transition_authorized_tote_items_to_committed
    simulate_order_filling(fill_all_tote_items)

    #verify there are no authorized
    assert_equal 0, ToteItem.where(status: ToteItem.states[:AUTHORIZED]).count    
    #verify there are no committed
    assert_equal 0, ToteItem.where(status: ToteItem.states[:COMMITTED]).count
    #verify there are filled
    assert ToteItem.where(status: ToteItem.states[:FILLED]).count > 0

    get new_bulk_buy_path
    assert 'bulk_buy/new'
    #puts @response.body
    assert total_bulk_buy_amount = assigns(:total_bulk_buy_amount) > 0
    filled_tote_items = assigns(:filled_tote_items)
    assert filled_tote_items.count > 0

    filled_tote_item_ids = []
    for tote_item in filled_tote_items
      filled_tote_item_ids << tote_item.id
    end

    num_bulk_buys = BulkBuy.count
    assert PurchaseReceivable.count == 0    
    post bulk_buys_path, filled_tote_item_ids: filled_tote_item_ids
    assert PurchaseReceivable.count > 0    

    assert_equal num_bulk_buys + 1, BulkBuy.count

    prs = PurchaseReceivable.all.to_a
    pr = prs[0]
    puts "amount=#{pr.amount.to_s}"
    puts pr.users.last.name
    puts "number of tote_items: #{pr.tote_items.count.to_s}"
  end
end