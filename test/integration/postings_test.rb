require 'test_helper'

class PostingsTest < ActionDispatch::IntegrationTest
  # test "the truth" do
  #   assert true
  # end

  def setup
    @user = users(:f1)
    @product = products(:apples)
    @unit_category = unit_categories(:weight)
    @unit_kind = unit_kinds(:pound)    
    @posting = postings(:postingf1apples)
  end  

  test "create new posting" do
    create_new_posting
  end

  test "edit new posting" do
    login_for(@user)
    mylive = @posting.live
    mynotlive = !@posting.live

    patch posting_path(@posting), posting: {
      description: "edited description",
      quantity_available: @posting.quantity_available,
      price: @posting.price,
      live: mynotlive
    }

    assert :success  
    assert_redirected_to @user    

  end

  #should copy an existing posting and have all same values and show up in the postings page
  test "should copy new posting" do
    login_for(@user)

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
    assert_redirected_to @user
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
    post login_path, session: { email: @user.email, password: 'dogdog' }
    assert_redirected_to @user
    follow_redirect!
  end

  def create_new_posting
    login_for(@user)
    assert_template 'users/show'
    assert_select "a[href=?]", login_path, count: 0
    assert_select "a[href=?]", logout_path
    assert_select "a[href=?]", user_path(@user)
    get new_posting_path

    delivery_date = Time.zone.today + 5.days
    if delivery_date.sunday?
      delivery_date += 1.day
    end

    post postings_path, posting: {
      description: "hi",
      quantity_available: 100,
      price: 2.97,
      user_id: @user.id,
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
