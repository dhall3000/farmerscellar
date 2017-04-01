require 'test_helper'

class ProducersControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get producers_new_url
    assert_response :success
  end

  test "should get create" do
    get producers_create_url
    assert_response :success
  end

  test "should get edit" do
    get producers_edit_url
    assert_response :success
  end

  test "should get update" do
    get producers_update_url
    assert_response :success
  end

  test "should get index" do
    get producers_index_url
    assert_response :success
  end

  test "should get show" do
    get producers_show_url
    assert_response :success
  end

  test "should get destroy" do
    get producers_destroy_url
    assert_response :success
  end

end
