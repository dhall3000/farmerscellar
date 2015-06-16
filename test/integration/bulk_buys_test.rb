require 'test_helper'
require 'authorization_helper'

class BulkBuysTest < Authorizer
  # test "the truth" do
  #   assert true
  # end
  def setup
    super
    @a1 = users(:a1)
  end

  test "fill should get processed" do

    assert_equal 0, Authorization.count, "there should be no authorizations in the database at the beginning of this test but there actually are #{Authorization.count}"

    customers = [@c1, @c2, @c3, @c4]
    create_authorization_for_customers(customers)

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
      while(tote_item = assigns(:tote_item))
      	puts "tote_item id: #{tote_item.id}"
      	post tote_items_next_path, {tote_item: {id: tote_item.id, posting_id: posting.id}}
      end      
    end

    #verify there are no authorized
    assert_equal 0, ToteItem.where(status: ToteItem.states[:AUTHORIZED]).count    
    #verify there are no committed
    assert_equal 0, ToteItem.where(status: ToteItem.states[:COMMITTED]).count
    #verify there are filled
    assert ToteItem.where(status: ToteItem.states[:FILLED]).count > 0

  	#puts "first ti status is #{ToteItem.first.status}"

  	#auth_test = AuthorizationsTest.new
  	#assert_not_nil auth_test

  end

end
