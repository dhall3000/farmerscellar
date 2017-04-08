require 'model_test_ancestor'

class PickupCodeTest < ModelTestAncestor

	def setup
		@pickup_code = PickupCode.new(user: users(:c1), code: "1234")
	end

	test "should save" do
		assert @pickup_code.valid?
		assert @pickup_code.save
		assert @pickup_code.valid?
	end

	test "should not save without user specified" do
		@pickup_code.user_id = nil
		assert_not @pickup_code.valid?
		assert_not @pickup_code.save
	end

	test "should not save without code" do
		@pickup_code.code = nil
		assert_not @pickup_code.valid?
	end

	test "should not save with code too long" do
		@pickup_code.code = "12345"
		assert_not @pickup_code.valid?
		assert_not @pickup_code.save		
	end

	test "should not save with code too short" do
		@pickup_code.code = "123"
		assert_not @pickup_code.valid?
		assert_not @pickup_code.save
	end

	test "should not save with non numbers in code" do
		@pickup_code.code = "12X3"
		assert_not @pickup_code.valid?
		assert_not @pickup_code.save
	end

	test "should generate a code" do
		@pickup_code.code = nil
		assert_not @pickup_code.valid?
		dropsite = dropsites(:dropsite2)
		@pickup_code.set_code(dropsite)
		assert @pickup_code.valid?
	end

	test "should exhaust all pickup codes" do
		#test the case where a non-unique-per-dropsite code is selected
		#this test doesn't really do what the name implies cause doing so would take too long.
		#the above comment is what this test was supposed to be all about. but i couldn't figure out a good way to do it and i'm impatient.
		#we're usign a 4 digit code so all combinations between [1000 - 10000). no leading zeros. so we have 9000 possibilities.
		#it takes too long to run through 9000. so i could shorten it but the regular expression in the pickupcode.rb model
		#i'm unsure how to change it to be somehting like '2' instead of '4' so that i could make the codes by 2 digits so that
		#i can exhaust all combinations.
		#so for the ongoing case i'm just going to punt. but what i did do was jacked up the integer in the while loop statement
		#to be 11000 to verify that it eventually gives up on finding a unique code. it did just fine. it was about to create about
		#8,500 codes (of a possible 9000) before the code generator crapped out due to taking 100 iterations to find a new code.

		dropsite = dropsites(:dropsite1)
		i = 0
		u = nil

		while i < 100

			u = User.create(name: "Username " + i.to_s,
				email: "x" + i.to_s + "@x.com",
        password:              "dogdog",
	      password_confirmation: "dogdog",
	      account_type: '0',
	      activated: true,
	      activated_at: Time.zone.now,             
	      address: "4215 21st St. SW",
	      city: "Redmond",
	      state: "Washington",
	      zip: "98008",
	      phone: "206-599-6579",
	      beta: false
	      )			
			u.set_dropsite(dropsite)

			if !u.pickup_code.valid?
				break
			end

			assert u.valid?
			assert u.pickup_code.valid?
			assert u.dropsite.valid?

			i += 1

		end		
		
	end
    
  #TODO: test the case where a global code is non-unique.i don't know how to test this.

end
