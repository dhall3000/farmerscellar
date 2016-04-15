require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def setup
    @user = User.new(name: "Example User", email: "user@example.com", password: "foobar", password_confirmation: "foobar", zip: 98033, account_type: 0)
  end

  test "should change dropsites" do
    assert @user.valid?
    assert_equal nil, @user.dropsite
    dropsite = dropsites(:dropsite1)
    @user.set_dropsite(dropsite)
    @user.reload
    assert @user.valid?
    assert @user.dropsite.valid?
    dropsite_id = @user.dropsite.id
    new_dropsite = dropsites(:dropsite2)    
    @user.set_dropsite(new_dropsite)
    @user.reload
    assert_not dropsite_id == @user.dropsite.id
  end

  test "should change pickup code when switching dropsites" do
    assert @user.valid?
    assert_equal nil, @user.dropsite
    dropsite = dropsites(:dropsite1)
    @user.set_dropsite(dropsite)
    @user.reload
    assert @user.valid?
    assert @user.dropsite.valid?
    old_code = @user.pickup_code.code
    dropsite_id = @user.dropsite.id
    new_dropsite = dropsites(:dropsite2)    
    @user.set_dropsite(new_dropsite)
    @user.reload
    assert_not dropsite_id == @user.dropsite.id
    new_code = @user.pickup_code.code
    assert new_code != old_code
  end

  test "should not change dropsite if dropsite is invalid" do

    assert @user.valid?
    dropsite = dropsites(:dropsite1)
    @user.set_dropsite(dropsite)
    @user.reload
    assert @user.valid?
    assert @user.dropsite.valid?
    dropsite_id = @user.dropsite.id
    @user.set_dropsite(nil)
    assert @user.valid?
    assert_equal dropsite_id, @user.dropsite.id

    @user.set_dropsite("david")
    assert @user.valid?
    assert_equal dropsite_id, @user.dropsite.id

    invalid_dropsite = Dropsite.new(name: nil, hours: "7-7", address: "1234 main", city: "Kirkland", state: "WA", zip: 98033)
    invalid_dropsite.save
    assert_not invalid_dropsite.valid?

    @user.set_dropsite(invalid_dropsite)
    assert_equal dropsite_id, @user.dropsite.id

  end

  test "should be invalid account type" do
    @user.account_type = nil
    assert_not @user.valid?
  end

    test "should be invalid account type one" do
    @user.account_type = -1
    assert_not @user.valid?
  end

  test "should be invalid account type two" do
    @user.account_type = -3
    assert_not @user.valid?
  end

  test "should be valid account type" do
    @user.account_type = 1
    assert_not @user.valid?
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "name should be present" do
    @user.name = "     "
    #commenting this out because name not necessary at Farmer's Cellar
    #assert_not @user.valid?
  end

  test "email should be present" do
  	@user.email = "    "
  	assert_not @user.valid?
  end

  test "name shouldn't be too long" do
  	@user.name = "a" * 51
  	assert_not @user.valid?
  end

  test "email shouldn't be too long" do
  	@user.email = "a" * 244 + "@example.com"
  	assert_not @user.valid?
  end

  test "email validation should accept valid email addresses" do
  	valid_addresses = %w[user@example.com USER@foo.com A_US-ER@foo.bar.org first.last@foo.jp alice+bob@baz.cn]
  	valid_addresses.each do |valid_address|
  		@user.email = valid_address
  		assert @user.valid?, "#{valid_address.inspect} should be valid"
  	end
  end

  test "email validation should reject invalid addresses" do
  	invalid_addresses = %w[user@example,com user_at_foo.org user.name@example.foo@bar_baz.com foo@bar+baz.com]
  	invalid_addresses.each do |invalid_address|
  		@user.email = invalid_address
  		assert_not @user.valid?, "#{invalid_address.inspect} should be invalid"
  	end
  end

  test "email addresses should be unique" do
  	duplicate_user = @user.dup
  	duplicate_user.email = @user.email.upcase
  	@user.save
  	assert_not duplicate_user.valid?
  end

  test "password should be above minimum length" do
  	@user.password = @user.password_confirmation = "a" * 5
  	assert_not @user.valid?
  end
end
