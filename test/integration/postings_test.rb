require 'test_helper'

class PostingsTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end

  def setup
    @farmer = users(:f1)
    @product = products(:apples)
    @unit_category = unit_categories(:weight)
    @unit_kind = unit_kinds(:pound)    
    @posting = postings(:postingf1apples)
  end  

  test "posting should recur" do
    
    price = 12.31
    #verify the post doesn't exist
    verify_post_presence(price, @unit_kind, exists = false)
    #create the post, with recurrence
    login_for(@farmer)
    delivery_date = Time.zone.today.midnight + 14.days
    commitment_zone_start = delivery_date - 2.days
    post postings_path, posting: {
      description: "my recurring posting",
      quantity_available: 100,
      price: price,
      user_id: @farmer.id,
      product_id: @product.id,
      unit_category_id: @unit_category.id,
      unit_kind_id: @unit_kind.id,
      live: true,
      delivery_date: delivery_date,
      commitment_zone_start: commitment_zone_start,
      posting_recurrence: {frequency: 1, on: true}
    }
    #verify exactly one post exists
    verify_post_presence(price, @unit_kind, exists = true)
    #wind the clock forward to between the commitment zone start and delivery date
    posting = Posting.where(price: price).last

    #add a toteitem to this posting. this is necessary or the rake helper won't transition this posting to committed
    posting.tote_items.create(quantity: 2, price: price, state: ToteItem.states[:AUTHORIZED], user: users(:c1))

    last_minute = posting.commitment_zone_start - 10.minutes
    travel_to last_minute

    while Time.zone.now < posting.commitment_zone_start + 10.minutes
      top_of_hour = Time.zone.now.min == 0

      if top_of_hour
        RakeHelper.do_hourly_tasks        
      end

      #as long as we're prior to the commitment zone start of the first posting we should
      #be able to see the post on the shopping page
      if Time.zone.now < posting.commitment_zone_start
        verify_post_presence(price, @unit_kind, true, posting.id)
      end

      last_minute = Time.zone.now
      travel 1.minute
    end

    #verify the old post is not visible
    #the old post should disappear from the postings page but the new one
    #should appear so that what you should actually find is there are now two postings in the
    #posting_recurrence.postings list but only one is visible in the postings page    
    assert_equal false, posting.posting_recurrence.postings.first.live
    assert_equal 2, posting.posting_recurrence.postings.count
    #verify the new post is visible
    verify_post_visibility(price, @unit_kind, 1)
        
    travel_back
    
  end

  def verify_post_presence(price, unit_kind, exists, posting_id = nil)

    if exists == true
      count = 1
    else
      count = 0
    end

    verify_post_visibility(price, unit_kind, count)    
    verify_post_existence(price, count, posting_id)

  end

  def verify_post_visibility(price, unit_kind, count)
    get postings_path
    assert :success
    assert_select 'div.price p', {text: number_to_currency(price) + " / " + unit_kind.name, count: count}
  end

  def verify_post_existence(price, count, posting_id = nil)

    postings = Posting.where(price: price)
    assert_not postings.nil?
    assert_equal count, postings.count

    if posting_id != nil
      assert_equal posting_id, postings.last.id
    end

  end

  test "create new posting" do
    create_new_posting
  end

  test "edit new posting" do
    login_for(@farmer)
    mylive = @posting.live
    mynotlive = !@posting.live

    patch posting_path(@posting), posting: {
      description: "edited description",
      quantity_available: @posting.quantity_available,
      price: @posting.price,
      live: mynotlive
    }

    assert :success  
    assert_redirected_to @farmer    

  end

  #should copy an existing posting and have all same values and show up in the postings page
  test "should copy new posting" do
    login_for(@farmer)

    get postings_path
    assert :success
    assert_select '.price', {text: "$2.75 / Pound", count: 1}
    
    #turn off the existing posting
    patch posting_path(@posting), posting: {
      description: "edited description",
      quantity_available: @posting.quantity_available,
      price: @posting.price,
      live: false
    }

    assert :success  
    assert_redirected_to @farmer
    get postings_path
    assert :success
    assert_select '.price', {text: "$2.75 / Pound", count: 0}

    #here is where we need to copy the posting
    get new_posting_path, posting_id: @posting.id
    posting = assigns(:posting)
    post postings_path, posting: {
      description: posting.description,
      quantity_available: posting.quantity_available,
      price: posting.price,
      user_id: posting.user_id,
      product_id: posting.product_id,
      unit_category_id: posting.unit_category_id,
      unit_kind_id: posting.unit_kind_id,
      live: posting.live,
      delivery_date: posting.delivery_date,
      commitment_zone_start: posting.commitment_zone_start
    }

    get postings_path
    assert :success
    assert_select '.price', {text: "$2.75 / Pound", count: 1}

  end

  def login_for(user)
    get_access_for(user)
    get login_path
    post login_path, session: { email: @farmer.email, password: 'dogdog' }
    assert_redirected_to @farmer
    follow_redirect!
  end

  def create_new_posting
    login_for(@farmer)
    assert_template 'users/show'
    assert_select "a[href=?]", login_path, count: 0
    assert_select "a[href=?]", logout_path
    assert_select "a[href=?]", user_path(@farmer)
    get new_posting_path

    delivery_date = Time.zone.today + 5.days
    if delivery_date.sunday?
      delivery_date += 1.day
    end

    post postings_path, posting: {
      description: "hi",
      quantity_available: 100,
      price: 2.97,
      user_id: @farmer.id,
      product_id: @product.id,
      unit_category_id: @unit_category.id,
      unit_kind_id: @unit_kind.id,
      live: true,
      delivery_date: delivery_date,
      commitment_zone_start: delivery_date - 2.days
      }

    assert :success
    posting = assigns(:posting)
    assert_redirected_to postings_path
    follow_redirect!
    assert_template 'postings/index'
    assert_select '.price', "$2.97 / Pound"
    
    return posting

  end
  
end
