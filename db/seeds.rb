#info: this is for testing a person authorizing a payment. user_id 6 (email: c3@c.com) has a bunch of items in their tote that are merely in the ADDED state. they should be able to do a checkout and then confirm authorization and have that move the state of thier toteitems to the AUTHORIZED state

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Upload.create(file_name: File.open(File.join("/home/david/fc/website/assets", "noimageavailable.png")), title: "NoProductImage")
Upload.create(file_name: File.open(File.join("/home/david/fc/website/assets", "FCLogo.jpg")), title: "LandingSplash")

dropsite_user_one = User.create!(name:  "dropsite one user",
             email: "da@d.com",
             password:              "dogdog",
             password_confirmation: "dogdog",
             account_type: '3',
             activated: true,
             activated_at: Time.zone.now,             
             address: "4215 21st St. SW",
             city: "Redmond",
             state: "Washington",
             zip: "98008",
             phone: "206-599-6579",
             beta: false
             )

f1 = User.create!(name:  "f1",
             email: "f1@f.com",
             password:              "dogdog",
             password_confirmation: "dogdog",
             account_type: '1',
             activated: true,
             activated_at: Time.zone.now,
             description: "producer of fine apples",
             address: "1234 main st",
             city: "Kirkland",
             state: "Washington",
             zip: "98033",
             phone: "206-588-6579",
             website: "www.f1.com",
             farm_name: "F1 FARM",
             beta: false,
             order_minimum_producer_net: 200
             )

AccessCode.create(user: f1, notes: "code for user 1")

f2 = User.create!(name:  "f2",
             email: "f2@f.com",
             password:              "dogdog",
             password_confirmation: "dogdog",
             account_type: '1',
             activated: true,
             activated_at: Time.zone.now,
             description: "we make grass fed beef",
             address: "9876 Focker St",
             city: "Bellevue",
             state: "Washington",
             zip: "98004",
             phone: "206-599-6579",
             website: "www.f2.com",
             farm_name: "F2 FARM",
             beta: false
             )

AccessCode.create(user: f2, notes: "code for user 2")

f3 = User.create!(name:  "f3",
             email: "f3@f.com",
             password:              "dogdog",
             password_confirmation: "dogdog",
             account_type: '1',
             activated: true,
             activated_at: Time.zone.now,
             description: "producers of fine food",
             address: "9876 Blaster St",
             city: "Bellevue",
             state: "Washington",
             zip: "98004",
             phone: "206-590-6579",
             website: "www.f3.com",
             farm_name: "F3 FARM",
             beta: false
             )

AccessCode.create(user: f3, notes: "code for user 3")

f4 = User.create!(name:  "f4",
             email: "f4@f.com",
             password:              "dogdog",
             password_confirmation: "dogdog",
             account_type: '1',
             activated: true,
             activated_at: Time.zone.now,
             description: "producers of sea food",
             address: "9876 Yollimer Rd",
             city: "Republic",
             state: "Washington",
             zip: "98114",
             phone: "206-650-6579",
             website: "www.f4.com",
             farm_name: "F4 FARM",
             beta: false,
             order_minimum_producer_net: 20
             )

AccessCode.create(user: f4, notes: "code for user 4")

c = User.create!(name:  "c1",
             email: "c1@c.com",
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

c1 = c
AccessCode.create(user: c, notes: "code for user 5")

c = User.create!(name:  "c2",
             email: "c2@c.com",
             password:              "dogdog",
             password_confirmation: "dogdog",
             account_type: '0',
             activated: true,
             activated_at: Time.zone.now,             
             address: "1964 29st St. NE",
             city: "Renton",
             state: "Washington",
             zip: "98021",
             phone: "206-599-6579",
             beta: false
             )

c2 = c
AccessCode.create(user: c, notes: "code for user 6")

c = User.create!(name:  "c3",
             email: "c3@c.com",
             password:              "dogdog",
             password_confirmation: "dogdog",
             account_type: '0',
             activated: true,
             activated_at: Time.zone.now,             
             address: "1946 31st St. SE",
             city: "Covington",
             state: "Washington",
             zip: "98099",
             phone: "206-799-6579",
             beta: false
             )

c3 = c
AccessCode.create(user: c, notes: "code for user 7")

c = User.create!(name:  "c4",
             email: "c4@c.com",
             password:              "dogdog",
             password_confirmation: "dogdog",
             account_type: '0',
             activated: true,
             activated_at: Time.zone.now,             
             address: "1974 33st St. South",
             city: "Ravensdale",
             state: "Washington",
             zip: "98001",
             phone: "206-899-6579",
             beta: false
             )

c4 = c
AccessCode.create(user: c, notes: "code for user 8")

c = User.create!(name:  "a1",
             email: "a1@a.com",
             password:              "dogdog",
             password_confirmation: "dogdog",
             account_type: '2',
             activated: true,
             activated_at: Time.zone.now,             
             address: "1234 Admin Road NE",
             city: "Bothell",
             state: "Washington",
             zip: "98009",
             phone: "206-699-6579",
             beta: false
             )

a1 = c
AccessCode.create(user: c, notes: "code for user 9")

shop = FoodCategory.create(name: "Shop")

produce = FoodCategory.create(name: "Produce", parent: shop)
upload = Upload.create(file_name: File.open(File.join("/home/david/fc/website/assets", "produce.jpg")))
produce.uploads << upload
produce.save

fruit = FoodCategory.create(name: "Fruit", parent: produce)
upload = Upload.create(file_name: File.open(File.join("/home/david/fc/website/assets", "fruit.jpg")))
fruit.uploads << upload
fruit.save

veggies = FoodCategory.create(name: "Vegetables", parent: produce)
upload = Upload.create(file_name: File.open(File.join("/home/david/fc/website/assets", "vegetables.jpg")))
veggies.uploads << upload
veggies.save

nuts = FoodCategory.create(name: "Nuts", parent: produce)
upload = Upload.create(file_name: File.open(File.join("/home/david/fc/website/assets", "nuts.jpg")))
nuts.uploads << upload
nuts.save

seeds = FoodCategory.create(name: "Seeds", parent: produce)
upload = Upload.create(file_name: File.open(File.join("/home/david/fc/website/assets", "seeds.jpg")))
seeds.uploads << upload
seeds.save

dairy = FoodCategory.create(name: "Dairy", parent: shop)
upload = Upload.create(file_name: File.open(File.join("/home/david/fc/website/assets", "dairy.jpg")))
dairy.uploads << upload
dairy.save

meat = FoodCategory.create(name: "Meat", parent: shop)
upload = Upload.create(file_name: File.open(File.join("/home/david/fc/website/assets", "meat.jpg")))
meat.uploads << upload
meat.save

bakery = FoodCategory.create(name: "Bakery", parent: shop)
upload = Upload.create(file_name: File.open(File.join("/home/david/fc/website/assets", "bakery.jpeg")))
bakery.uploads << upload
bakery.save

product_apples = Product.create(name: "Fuji Apples", food_category: fruit)
product_carrots = Product.create(name: "Carrots", food_category: veggies)
product_milk = Product.create(name: "Milk", food_category: dairy)
product_beef = Product.create(name: "Beef", food_category: meat)
product_chicken = Product.create(name: "Chicken", food_category: meat)
product_asparagus = Product.create(name: "Asparagus", food_category: veggies)
product_oranges = Product.create(name: "Oranges", food_category: fruit)
product_celery = Product.create(name: "Celery", food_category: produce)
product_spinach = Product.create(name: "Spinach", food_category: produce)
product_avocado = Product.create(name: "Avocado", food_category: produce)
product_basil = Product.create(name: "Basil", food_category: produce)

Unit.create(name: "Fluid Ounce")
Unit.create(name: "Pint")
Unit.create(name: "Quart")
half_gallon = Unit.create(name: "Half Gallon")
gallon = Unit.create(name: "Gallon")

Unit.create(name: "Grain")
Unit.create(name: "Ounce")
pound = Unit.create(name: "Pound")
Unit.create(name: "Ton")

whole = Unit.create(name: "Whole")
Unit.create(name: "Half")
Unit.create(name: "Quarter")
Unit.create(name: "8th")
Unit.create(name: "16th")
bunch = Unit.create(name: "Bunch")

def next_friday
  i = 1
  while !(Time.zone.now + i.days).friday?   
    i += 1
  end
  return (Time.zone.now + i.days).midnight
end

standard_order_cutoff = next_friday - 2.days

#Apples
posting_apples = Posting.create(
  live: true,
  delivery_date: next_friday,
  order_cutoff: standard_order_cutoff,
  product_id: product_apples.id,
  price: 2.75,
  producer_net_unit: 2.25,
  user_id: f1.id,
  unit_id: 8,
  description: "product attribute x, y & z",
  description_body: "these apples are all organic grown with no pesticides. they are 2nds so might have some spotting but they are just as tasty and possibly more nutritious too.",
  important_notes: "These are 2nds",
  important_notes_body: "These are 2nds so they have some cosmetic blemishes but they are just as tasty and crunchy and possibly even more nutritious"
  )
#Asparagus
posting_asparagus = Posting.create(live: true, delivery_date: next_friday, order_cutoff: standard_order_cutoff, product_id: product_asparagus.id, price: 3.25, producer_net_unit: 3.00, user_id: f1.id, unit_id: 8, description: "product attribute x, y & z", description_body: "these Asparagus are all organic grown with no pesticides. they are crispy and crunchy and tasty as ever.")
#Milk
posting_milk = Posting.create(live: true, delivery_date: next_friday, order_cutoff: standard_order_cutoff, product_id: product_milk.id, producer_net_unit: 1.75, price: 2.00, user_id: f2.id, unit_id: 5, description: "product attribute x, y & z", description_body: "these milks are all organic grown with no pesticides. they are raw. no homogeneization. they are 2nds so might have some spotting but they are just as tasty and possibly more nutritious too.")
#Beef
posting_beef = Posting.create(live: true, delivery_date: next_friday, order_cutoff: standard_order_cutoff, product_id: product_beef.id, producer_net_unit: 3.25, price: 3.75, user_id: f2.id, unit_id: pound.id, description: "product attribute x, y & z", description_body: "these beefs are all organic grown with no pesticides. they are crispy and crunchy and tasty as ever.")
#Carrots
posting_carrots = Posting.create(live: true, delivery_date: next_friday, order_cutoff: standard_order_cutoff, product_id: product_carrots.id, producer_net_unit: 1.95, price: 2.25, user_id: f3.id, unit_id: 8, description: "product attribute x, y & z", description_body: "yummy, crunchy carrots. tastiest ever!")
#Chicken
posting_chicken = Posting.create(live: true, delivery_date: next_friday, order_cutoff: standard_order_cutoff, product_id: product_chicken.id, producer_net_unit: 1.00, price: 1.50, user_id: f3.id, unit_id: pound.id, description: "product attribute x, y & z", description_body: "best whole chickens around. all grass fed on clean, organic fields. no antibiotics. no supplements. just lots of grass and all the bugs they can eat! :)")
#Oranges
posting_oranges = Posting.create(live: true, delivery_date: next_friday, order_cutoff: standard_order_cutoff, product_id: product_oranges.id, producer_net_unit: 0.95, price: 1.25, user_id: f4.id, unit_id: 8, description: "product attribute x, y & z", description_body: "best oranges ever!")
#Celery
posting_celery = Posting.create(product_id_code: "ZXB-9F", units_per_case: 10, live: true, delivery_date: next_friday, order_cutoff: standard_order_cutoff, product_id: product_celery.id, producer_net_unit: 0.75, price: 1.00, user_id: f4.id, unit_id: 8, description: "product attribute x, y & z", description_body: "best celery ever!")
upload = Upload.create(file_name: File.open(File.join("/home/david/fc/website/assets", "celery.jpg")))
posting_celery.uploads << upload
posting_celery.save
#Spinach
posting_spinach = Posting.create(product_id_code: "super9", units_per_case: 10, live: true, delivery_date: next_friday + 1.day, order_cutoff: standard_order_cutoff, product_id: product_spinach.id, producer_net_unit: 0.75, price: 1.00, user_id: f3.id, unit_id: 8, description: "organic", description_body: "best organic spinach ever!")
upload = Upload.create(file_name: File.open(File.join("/home/david/fc/website/assets", "spinach.jpg")))
posting_spinach.uploads << upload
posting_spinach.save
#Avocado
posting_avocado = Posting.create(live: true, delivery_date: next_friday + 7.days, order_cutoff: Time.zone.today - 2.days, product_id: product_avocado.id, producer_net_unit: 2.00, price: 2.29, user_id: f4.id, unit_id: whole.id, description: "product attribute x, y & z", description_body: "best avocado ever!")
upload = Upload.create(file_name: File.open(File.join("/home/david/fc/website/assets", "avocado.png")))
posting_avocado.uploads << upload
posting_avocado.save
#Basil
posting_basil = Posting.create(live: true, delivery_date: next_friday + 14.days, order_cutoff: Time.zone.today - 2.days, product_id: product_basil.id, producer_net_unit: 2.75, price: 2.97, user_id: f4.id, unit_id: bunch.id, unit_body: "A 'bunch' is about as much as you can grab with one handful", description: "product attribute x, y & z", description_body: "best basil ever!")
upload = Upload.create(file_name: File.open(File.join("/home/david/fc/website/assets", "basil.jpg")))
posting_basil.uploads << upload
posting_basil.save

develop_creditor_orders_controller = false

if develop_creditor_orders_controller
  Posting.where(order_cutoff: standard_order_cutoff).update_all(order_cutoff: Time.zone.now.midnight)
end

posting_recurrence = PostingRecurrence.new(on: true, frequency: 1)
posting_recurrence.postings << posting_celery
posting_recurrence.save

posting_recurrence = PostingRecurrence.new(on: true, frequency: 2)
posting_recurrence.postings << posting_apples
posting_recurrence.save

posting_recurrence = PostingRecurrence.new(on: true, frequency: 5)
posting_recurrence.postings << posting_asparagus
posting_recurrence.save

delivery_date = Time.zone.tomorrow

if delivery_date.wday == STARTOFWEEK
  delivery_date = delivery_date + 1.day
end

milk = Posting.create(
      live: true,
      delivery_date: delivery_date,
      order_cutoff: Time.zone.yesterday,
      product_id: 3,      
      price: 2.00,
      producer_net_unit: 1.75,
      user_id: f2.id,
      unit_id: 5,
      description: "product attributes x, y & z",
      description_body: "these milks are all organic grown with no pesticides. they are raw. no homogeneization. they are 2nds so might have some spotting but they are just as tasty and possibly more nutritious too."
      )

posting_recurrence = PostingRecurrence.new(on: true, frequency: 4)
posting_recurrence.postings << milk
posting_recurrence.save

milk.transition(:order_cutoffed)

#Apples
ToteItem.create(quantity: 2, price: posting_apples.price, state: ToteItem.states[:ADDED], user_id: c3.id, posting_id: posting_apples.id).transition(:customer_authorized)
ToteItem.create(quantity: 1, price: posting_apples.price, state: ToteItem.states[:ADDED], user_id: c4.id, posting_id: posting_apples.id).transition(:customer_authorized)
ToteItem.create(quantity: 5, price: posting_apples.price, state: ToteItem.states[:ADDED], user_id: c2.id, posting_id: posting_apples.id).transition(:customer_authorized)
ToteItem.create(quantity: 3, price: posting_apples.price, state: ToteItem.states[:ADDED], user_id: c1.id, posting_id: posting_apples.id).transition(:customer_authorized)

#Milk
ToteItem.create(quantity: 2, price: posting_milk.price, state: ToteItem.states[:ADDED], user_id: c3.id, posting_id: posting_milk.id).transition(:customer_authorized)
ToteItem.create(quantity: 3, price: posting_milk.price, state: ToteItem.states[:ADDED], user_id: c4.id, posting_id: posting_milk.id).transition(:customer_authorized)
ToteItem.create(quantity: 4, price: posting_milk.price, state: ToteItem.states[:ADDED], user_id: c2.id, posting_id: posting_milk.id).transition(:customer_authorized)
ToteItem.create(quantity: 1, price: posting_milk.price, state: ToteItem.states[:ADDED], user_id: c1.id, posting_id: posting_milk.id).transition(:customer_authorized)

#Chicken
ToteItem.create(quantity: 1, price: posting_chicken.price, state: ToteItem.states[:ADDED], user_id: c3.id, posting_id: posting_chicken.id).transition(:customer_authorized)
ToteItem.create(quantity: 4, price: posting_chicken.price, state: ToteItem.states[:ADDED], user_id: c4.id, posting_id: posting_chicken.id).transition(:customer_authorized)
ToteItem.create(quantity: 2, price: posting_chicken.price, state: ToteItem.states[:ADDED], user_id: c2.id, posting_id: posting_chicken.id).transition(:customer_authorized)
ToteItem.create(quantity: 7, price: posting_chicken.price, state: ToteItem.states[:ADDED], user_id: c1.id, posting_id: posting_chicken.id).transition(:customer_authorized)

#Celery
ToteItem.create(quantity: 3, price: posting_celery.price, state: ToteItem.states[:ADDED], user_id: c1.id, posting_id: posting_celery.id).transition(:customer_authorized)
ToteItem.create(quantity: 1, price: posting_celery.price, state: ToteItem.states[:ADDED], user_id: c2.id, posting_id: posting_celery.id).transition(:customer_authorized)
ToteItem.create(quantity: 5, price: posting_celery.price, state: ToteItem.states[:ADDED], user_id: c3.id, posting_id: posting_celery.id).transition(:customer_authorized)
ToteItem.create(quantity: 2, price: posting_celery.price, state: ToteItem.states[:ADDED], user_id: c4.id, posting_id: posting_celery.id)

#Asparagus
ToteItem.create(quantity: 100, price: posting_asparagus.price, state: ToteItem.states[:ADDED], user_id: c4.id, posting_id: posting_asparagus.id).transition(:customer_authorized)

Dropsite.create(name: "Farmer's Cellar", phone: "206-588-6579", hours: "8 - 8", address: "9827 128TH AVE NE", city: "Kirkland", state: "WA", zip: 98033, active: true, access_instructions: "punch in 123 and hit enter")
WebsiteSetting.create(new_customer_access_code_required: false, recurring_postings_enabled: true)

BusinessInterface.create(name: "F1 FARM", order_email: f1.email, payment_method: BusinessInterface.payment_methods[:PAYPAL], paypal_email: f1.email, user: f1)
BusinessInterface.create(name: "F2 FARM", order_email: f2.email, payment_method: BusinessInterface.payment_methods[:PAYPAL], paypal_email: f2.email, user: f2)
BusinessInterface.create(name: "F3 FARM", order_email: f3.email, payment_method: BusinessInterface.payment_methods[:PAYPAL], paypal_email: f3.email, user: f3)
BusinessInterface.create(name: "F4 FARM", order_email: f4.email, payment_method: BusinessInterface.payment_methods[:PAYPAL], paypal_email: f4.email, user: f4)

if develop_creditor_orders_controller
  RakeHelper.do_hourly_tasks
end

PageUpdate.create(name: "HowThingsWork", update_time: Time.zone.now)
PageUpdate.create(name: "News", update_time: Time.zone.now)

co = CreditorOrder.submit(f1.postings)
co.add_payment(Payment.create(amount: 100))

co = CreditorOrder.submit(f2.postings)
co.add_payment(Payment.create(amount: 100))
co.add_payment_payable(PaymentPayable.create(amount: 100, amount_paid: 0, fully_paid: false))

email = Email.new(subject: "Apples have worms", body: "Sorry to say but you should expect to eat into some worms on this batch of apples")
email.postings << posting_apples
email.save