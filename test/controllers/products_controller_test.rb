require 'integration_helper'

class ProductsControllerTest < IntegrationHelper
  
  def setup
    @admin = users(:a1)
  end

  test "should get new" do
    log_in_as(@admin)
    get new_product_path
    assert_response :success
  end

  test "should get create" do
    
  end

  test "should get edit" do
    
  end

  test "should get update" do
    
  end

  test "should get show" do

  end

  test "should get index" do
    log_in_as(@admin)
    get products_path
    assert_response :success
  end

  test "should get destroy" do
    
  end

end
