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
    patch posting_path(@posting), posting: {description: "edited description", quantity_available: @posting.quantity_available, price: @posting.price, live: mynotlive, delivery_date: @posting.delivery_date}
    assert_redirected_to @user    
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
    post postings_path, posting: {description: "hi", quantity_available: 100, price: 2.50, user_id: @user.id, product_id: @product.id, unit_category_id: @unit_category.id, unit_kind_id: @unit_kind.id, delivery_date: "2015-08-28", live: true}
  end
  
end
