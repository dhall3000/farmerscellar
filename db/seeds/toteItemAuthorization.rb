#info: this is for testing a person authorizing a payment. user_id 6 (email: c3@c.com) has a bunch of items in their tote that are merely in the ADDED state. they should be able to do a checkout and then confirm authorization and have that move the state of thier toteitems to the AUTHORIZED state

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

User.create!(name:  "f1",
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
             farmer_approval: 't',
             farm_name: "F1 FARM"
             )

User.create!(name:  "f2",
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
             farmer_approval: 't',
             farm_name: "F2 FARM"
             )

User.create!(name:  "f3",
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
             farmer_approval: 't',
             farm_name: "F3 FARM"
             )

User.create!(name:  "c1",
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
             phone: "206-599-6579"
             )

User.create!(name:  "c2",
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
             phone: "206-599-6579"
             )

User.create!(name:  "c3",
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
             phone: "206-799-6579"
             )

User.create!(name:  "c4",
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
             phone: "206-899-6579"
             )

User.create!(name:  "a1",
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
             phone: "206-699-6579"
             )

Product.create(name: "Fuji Apples")
Product.create(name: "Carrots")
Product.create(name: "Milk")
Product.create(name: "Beef")
Product.create(name: "Chicken")
Product.create(name: "Asparagus")

volume = UnitCategory.create(name: "Volume")
weight = UnitCategory.create(name: "Weight")
count = UnitCategory.create(name: "Count")

volume.unit_kinds.create(name: "Fluid Ounce")
volume.unit_kinds.create(name: "Pint")
volume.unit_kinds.create(name: "Quart")
volume.unit_kinds.create(name: "Half Gallon")
volume.unit_kinds.create(name: "Gallon")

weight.unit_kinds.create(name: "Grain")
weight.unit_kinds.create(name: "Ounce")
weight.unit_kinds.create(name: "Pound")
weight.unit_kinds.create(name: "Ton")

count.unit_kinds.create(name: "Whole")
count.unit_kinds.create(name: "Half")
count.unit_kinds.create(name: "Quarter")
count.unit_kinds.create(name: "8th")
count.unit_kinds.create(name: "16th")

#Apples
Posting.create(product_id: 1, quantity_available: 1000, price: 2.75, user_id: 1, unit_category_id: 2, unit_kind_id: 8, description: "these apples are all organic grown with no pesticides. they are 2nds so might have some spotting but they are just as tasty and possibly more nutritious too.")
#Asparagus
Posting.create(product_id: 6, quantity_available: 100, price: 3.25, user_id: 1, unit_category_id: 2, unit_kind_id: 8, description: "these Asparagus are all organic grown with no pesticides. they are crispy and crunchy and tasty as ever.")
#Milk
Posting.create(product_id: 3, quantity_available: 25, price: 12.00, user_id: 2, unit_category_id: 1, unit_kind_id: 5, description: "these milks are all organic grown with no pesticides. they are raw. no homogeneization. they are 2nds so might have some spotting but they are just as tasty and possibly more nutritious too.")
#Beef
Posting.create(product_id: 4, quantity_available: 10, price: 325, user_id: 2, unit_category_id: 3, unit_kind_id: 11, description: "these beefs are all organic grown with no pesticides. they are crispy and crunchy and tasty as ever.")
#Carrots
Posting.create(product_id: 2, quantity_available: 15, price: 2.25, user_id: 3, unit_category_id: 2, unit_kind_id: 8, description: "yummy, crunchy carrots. tastiest ever!")
#Chicken
Posting.create(product_id: 5, quantity_available: 50, price: 20, user_id: 3, unit_category_id: 3, unit_kind_id: 10, description: "best whole chickens around. all grass fed on clean, organic fields. no antibiotics. no supplements. just lots of grass and all the bugs they can eat! :)")

#Apples
ToteItem.create(quantity: 2, price: 2.75, status: ToteItem.states[:ADDED], user_id: 6, posting_id: 1)
ToteItem.create(quantity: 10, price: 2.75, status: ToteItem.states[:ADDED], user_id: 7, posting_id: 1)
ToteItem.create(quantity: 5, price: 2.75, status: ToteItem.states[:COMMITTED], user_id: 5, posting_id: 1)
ToteItem.create(quantity: 40, price: 2.75, status: ToteItem.states[:COMMITTED], user_id: 4, posting_id: 1)

#Milk
ToteItem.create(quantity: 5, price: 12, status: ToteItem.states[:ADDED], user_id: 6, posting_id: 3)
ToteItem.create(quantity: 2, price: 12, status: ToteItem.states[:ADDED], user_id: 7, posting_id: 3)
ToteItem.create(quantity: 3, price: 12, status: ToteItem.states[:COMMITTED], user_id: 5, posting_id: 3)
ToteItem.create(quantity: 1, price: 12, status: ToteItem.states[:COMMITTED], user_id: 4, posting_id: 3)

#Chicken
ToteItem.create(quantity: 1, price: 12, status: ToteItem.states[:ADDED], user_id: 6, posting_id: 6)
ToteItem.create(quantity: 4, price: 12, status: ToteItem.states[:ADDED], user_id: 7, posting_id: 6)
ToteItem.create(quantity: 10, price: 12, status: ToteItem.states[:COMMITTED], user_id: 5, posting_id: 6)
ToteItem.create(quantity: 15, price: 12, status: ToteItem.states[:COMMITTED], user_id: 4, posting_id: 6)

#ToteItem.create(quantity: 5, price: 2.75, status: ToteItem.states[:COMMITTED], user_id: 1, posting_id: 1)
#ToteItem.create(quantity: 7, price: 3.25, status: ToteItem.states[:COMMITTED], user_id: 1, posting_id: 2)
#ToteItem.create(quantity: 10, price: 2.75, status: ToteItem.states[:ADDED], user_id: 2, posting_id: 1)
#ToteItem.create(quantity: 15, price: 2.75, status: ToteItem.states[:COMMITTED], user_id: 3, posting_id: 1)
#ToteItem.create(quantity: 20, price: 2.75, status: ToteItem.states[:COMMITTED], user_id: 4, posting_id: 1)

#Unit.create(name: "Gallon")
#Unit.create(name: "Pound")
#unit_count = Unit.create(name: "Count")

#unit_modifier = unit_count.unit_modifiers.create(name: "Whole", multiplier: 1.0)
#unit_modifier = unit_count.unit_modifiers.create(name: "Half", multiplier: 0.5)
#unit_modifier = unit_count.unit_modifiers.create(name: "Quarter", multiplier: 0.25)
#unit_modifier = unit_count.unit_modifiers.create(name: "8th", multiplier: 0.125)
#unit_modifier = unit_count.unit_modifiers.create(name: "16th", multiplier: 0.0625)

#User.create!(name:  "david",
#             email: "david@x.com",
#             password:              "dogdog",
#             password_confirmation: "dogdog",
#             account_type: '2',
#             activated: true,
#             activated_at: Time.zone.now)

#99.times do |n|
#  name  = Faker::Name.name
#  email = "example-#{n+1}@railstutorial.org"
#  password = "password"
#  User.create!(name:  name,
#               email: email,
#               password:              password,
#               password_confirmation: password,
#               account_type: 0,
#               activated: true,
#               activated_at: Time.zone.now)
#end
