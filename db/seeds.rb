#info: this is for testing a person authorizing a payment. user_id 6 (email: c3@c.com) has a bunch of items in their tote that are merely in the ADDED state. they should be able to do a checkout and then confirm authorization and have that move the state of thier toteitems to the AUTHORIZED state

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

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
             agreement: 1,
             farm_name: "F1 FARM",
             beta: false
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
             agreement: 1,
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
             agreement: 1,
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
             agreement: 1,
             farm_name: "F4 FARM",
             beta: false
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

AccessCode.create(user: c, notes: "code for user 9")

apples = Product.create(name: "Fuji Apples")
carrots = Product.create(name: "Carrots")
milk = Product.create(name: "Milk")
beef = Product.create(name: "Beef")
chicken = Product.create(name: "Chicken")
asparagus = Product.create(name: "Asparagus")
oranges = Product.create(name: "Oranges")
celery = Product.create(name: "Celery")
avocado = Product.create(name: "Avocado")
basil = Product.create(name: "Basil")

Unit.create(name: "Fluid Ounce")
Unit.create(name: "Pint")
Unit.create(name: "Quart")
Unit.create(name: "Half Gallon")
Unit.create(name: "Gallon")

Unit.create(name: "Grain")
Unit.create(name: "Ounce")
Unit.create(name: "Pound")
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

f1.producer_product_commissions.create(product: apples, commission: 0.05)
f1.producer_product_commissions.create(product: asparagus, commission: 0.15)
f2.producer_product_commissions.create(product: milk, commission: 0.10)
f2.producer_product_commissions.create(product: beef, commission: 0.03)
f3.producer_product_commissions.create(product: carrots, commission: 0.04)
f3.producer_product_commissions.create(product: chicken, commission: 0.07)
f4.producer_product_commissions.create(product: oranges, commission: 0.08)
f4.producer_product_commissions.create(product: celery, commission: 0.12)
f4.producer_product_commissions.create(product: avocado, commission: 0.08)
f4.producer_product_commissions.create(product: basil, commission: 0.06)

#Apples
apples = Posting.create(live: true, delivery_date: next_friday, commitment_zone_start: next_friday - 2.days, product_id: 1, quantity_available: 1000, price: 2.75, user_id: f1.id, unit_id: 8, description: "these apples are all organic grown with no pesticides. they are 2nds so might have some spotting but they are just as tasty and possibly more nutritious too.")
#Asparagus
asparagus = Posting.create(live: true, delivery_date: next_friday, commitment_zone_start: next_friday - 2.days, product_id: 6, quantity_available: 100, price: 3.25, user_id: f1.id, unit_id: 8, description: "these Asparagus are all organic grown with no pesticides. they are crispy and crunchy and tasty as ever.")
#Milk
Posting.create(live: true, delivery_date: next_friday, commitment_zone_start: next_friday - 2.days, product_id: 3, quantity_available: 25, price: 2.00, user_id: f2.id, unit_id: 5, description: "these milks are all organic grown with no pesticides. they are raw. no homogeneization. they are 2nds so might have some spotting but they are just as tasty and possibly more nutritious too.")
#Beef
Posting.create(live: true, delivery_date: next_friday, commitment_zone_start: next_friday - 2.days, product_id: 4, quantity_available: 10, price: 3.75, user_id: f2.id, unit_id: 11, description: "these beefs are all organic grown with no pesticides. they are crispy and crunchy and tasty as ever.")
#Carrots
Posting.create(live: true, delivery_date: next_friday, commitment_zone_start: next_friday - 2.days, product_id: 2, quantity_available: 15, price: 2.25, user_id: f3.id, unit_id: 8, description: "yummy, crunchy carrots. tastiest ever!")
#Chicken
Posting.create(live: true, delivery_date: next_friday, commitment_zone_start: next_friday - 2.days, product_id: 5, quantity_available: 50, price: 1.50, user_id: f3.id, unit_id: 10, description: "best whole chickens around. all grass fed on clean, organic fields. no antibiotics. no supplements. just lots of grass and all the bugs they can eat! :)")
#Oranges
Posting.create(live: true, delivery_date: next_friday, commitment_zone_start: next_friday - 2.days, product_id: 7, quantity_available: 100, price: 1.25, user_id: f4.id, unit_id: 8, description: "best oranges ever!")
#Celery
Posting.create(live: true, delivery_date: next_friday, commitment_zone_start: next_friday - 2.days, product_id: 8, quantity_available: 100, price: 2.50, user_id: f4.id, unit_id: 8, description: "best celery ever!")
#Avocado
Posting.create(live: true, delivery_date: Time.zone.today, commitment_zone_start: Time.zone.today - 2.days, product_id: avocado.id, quantity_available: 100, price: 2.29, user_id: f4.id, unit_id: whole.id, description: "best avocado ever!")
#Basil
Posting.create(live: true, delivery_date: Time.zone.today, commitment_zone_start: Time.zone.today - 2.days, product_id: basil.id, quantity_available: 100, price: 2.97, user_id: f4.id, unit_id: bunch.id, description: "best basil ever!")

posting_recurrence = PostingRecurrence.new(on: true, frequency: 6)
posting_recurrence.postings << apples
posting_recurrence.save

posting_recurrence = PostingRecurrence.new(on: true, frequency: 5)
posting_recurrence.postings << asparagus
posting_recurrence.save

delivery_date = Time.zone.tomorrow

if delivery_date.sunday?
  delivery_date = delivery_date + 1.day
end

milk = Posting.create(
      live: true,
      delivery_date: delivery_date,
      commitment_zone_start: Time.zone.yesterday,
      product_id: 3,
      quantity_available: 25,
      price: 2.00,
      user_id: f2.id,
      unit_id: 5,
      description: "these milks are all organic grown with no pesticides. they are raw. no homogeneization. they are 2nds so might have some spotting but they are just as tasty and possibly more nutritious too."
      )

posting_recurrence = PostingRecurrence.new(on: true, frequency: 6)
posting_recurrence.postings << milk
posting_recurrence.save
milk.transition(:commitment_zone_started)

#Apples
ToteItem.create(quantity: 2, price: 2.75, state: ToteItem.states[:AUTHORIZED], user_id: 7, posting_id: 1)
ToteItem.create(quantity: 1, price: 2.75, state: ToteItem.states[:AUTHORIZED], user_id: 8, posting_id: 1)
ToteItem.create(quantity: 5, price: 2.75, state: ToteItem.states[:AUTHORIZED], user_id: 6, posting_id: 1)
ToteItem.create(quantity: 3, price: 2.75, state: ToteItem.states[:AUTHORIZED], user_id: 5, posting_id: 1)

#Milk
ToteItem.create(quantity: 2, price: 2.00, state: ToteItem.states[:AUTHORIZED], user_id: 7, posting_id: 3)
ToteItem.create(quantity: 3, price: 2.00, state: ToteItem.states[:AUTHORIZED], user_id: 8, posting_id: 3)
ToteItem.create(quantity: 4, price: 2.00, state: ToteItem.states[:AUTHORIZED], user_id: 6, posting_id: 3)
ToteItem.create(quantity: 1, price: 2.00, state: ToteItem.states[:AUTHORIZED], user_id: 5, posting_id: 3)

#Chicken
ToteItem.create(quantity: 1, price: 1.50, state: ToteItem.states[:AUTHORIZED], user_id: 7, posting_id: 6)
ToteItem.create(quantity: 4, price: 1.50, state: ToteItem.states[:AUTHORIZED], user_id: 8, posting_id: 6)
ToteItem.create(quantity: 2, price: 1.50, state: ToteItem.states[:AUTHORIZED], user_id: 6, posting_id: 6)
ToteItem.create(quantity: 7, price: 1.50, state: ToteItem.states[:AUTHORIZED], user_id: 5, posting_id: 6)

#Celery
ToteItem.create(quantity: 5, price: 2.50, state: ToteItem.states[:AUTHORIZED], user_id: 7, posting_id: 8)
ToteItem.create(quantity: 2, price: 2.50, state: ToteItem.states[:AUTHORIZED], user_id: 8, posting_id: 8)
ToteItem.create(quantity: 1, price: 2.50, state: ToteItem.states[:AUTHORIZED], user_id: 6, posting_id: 8)
ToteItem.create(quantity: 3, price: 2.50, state: ToteItem.states[:AUTHORIZED], user_id: 5, posting_id: 8)

Dropsite.create(name: "Farmer's Cellar", phone: "206-588-6579", hours: "8 - 8", address: "9827 128TH AVE NE", city: "Kirkland", state: "WA", zip: 98033, active: true, access_instructions: "punch in 123 and hit enter")
WebsiteSetting.create(new_customer_access_code_required: false, recurring_postings_enabled: true)