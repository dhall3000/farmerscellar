require 'test_helper'
require 'authorization_helper'

class AuthorizationsTest < Authorizer

  # test "the truth" do
  #   assert true
  # end

  #this should create an auth in the db for each customer that has tote items
  test "should create new authorizations" do
    puts "test: should create new authorizations"
    #first verify there are currently no auths in the db
    assert_equal 0, Authorization.count, "there should be no authorizations in the database at the beginning of this test but there actually are #{Authorization.count}"

    customers = [@c1, @c2, @c3, @c4]
    create_authorization_for_customers(customers)

  end

end