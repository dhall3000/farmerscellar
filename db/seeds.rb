admin = User.create!(name:  "david (admin)",
             email: "davideltonhall@gmail.com",
             password:              "dogdog",
             password_confirmation: "dogdog",
             account_type: '2',
             activated: true,
             activated_at: Time.zone.now,             
             address: "9827 128TH AVE NE",
             city: "Kirkland",
             state: "Washington",
             zip: "98033",
             phone: "206-588-6579",
             beta: true
             )

AccessCode.create(user: admin, notes: "code for admin")

art = User.create!(name:  "Art",
             email: "david@farmerscellar.com",
             password:              "dogdog",
             password_confirmation: "dogdog",
             account_type: '1',
             activated: true,
             activated_at: Time.zone.now,
             description: "Organic produce from Tonasket, WA",
             address: "address unknown",
             city: "Tonasket",
             state: "Washington",
             zip: "98855",
             phone: "206-588-6579",
             website: "www.farmerscellar.com",
             agreement: 1,
             farm_name: "Art's Produce Farm",
             beta: true
             )

AccessCode.create(user: art, notes: "code for art")

heirloom_tomato = Product.create(name: "Heirloom Tomatoes")
heirloom_cherry_tomatoes = Product.create(name: "Heirloom Cherry Tomatoes")
black_czech_peppers = Product.create(name: "Black Czech Peppers")
eggplant = Product.create(name: "Eggplant")
garlic = Product.create(name: "Garlic")
kale = Product.create(name: "Kale")
beets = Product.create(name: "Beets")
shallots = Product.create(name: "Shallots")

art_commission = 0.02

art.producer_product_commissions.create(product: heirloom_tomato, commission: art_commission)
art.producer_product_commissions.create(product: heirloom_cherry_tomatoes, commission: art_commission)
art.producer_product_commissions.create(product: black_czech_peppers, commission: art_commission)
art.producer_product_commissions.create(product: eggplant, commission: art_commission)
art.producer_product_commissions.create(product: garlic, commission: art_commission)
art.producer_product_commissions.create(product: kale, commission: art_commission)
art.producer_product_commissions.create(product: beets, commission: art_commission)
art.producer_product_commissions.create(product: shallots, commission: art_commission)

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

def next_friday
  i = 1
  while !(Date.today + i).friday?   
    i += 1
  end
  Date.today + i
end

#heirloom tomato
Posting.create(delivery_date: next_friday, product_id: 1, quantity_available: 1000, price: 2.30, user_id: 2, unit_category_id: 2, unit_kind_id: 8, description: "No product description provided")
#heirloom cherry tomato
Posting.create(delivery_date: next_friday, product_id: 2, quantity_available: 1000, price: 3.50, user_id: 2, unit_category_id: 1, unit_kind_id: 2, description: "No product description provided")
#black check pepper
Posting.create(delivery_date: next_friday, product_id: 3, quantity_available: 1000, price: 4.00, user_id: 2, unit_category_id: 2, unit_kind_id: 8, description: "No product description provided")
#eggplant
Posting.create(delivery_date: next_friday, product_id: 4, quantity_available: 1000, price: 2.25, user_id: 2, unit_category_id: 2, unit_kind_id: 8, description: "No product description provided")
#garlic
Posting.create(delivery_date: next_friday, product_id: 5, quantity_available: 1000, price: 7.00, user_id: 2, unit_category_id: 2, unit_kind_id: 8, description: "No product description provided")
#beets
Posting.create(delivery_date: next_friday, product_id: 6, quantity_available: 1000, price: 1.50, user_id: 2, unit_category_id: 2, unit_kind_id: 8, description: "No product description provided")
#shallots
Posting.create(delivery_date: next_friday, product_id: 7, quantity_available: 1000, price: 4.50, user_id: 2, unit_category_id: 2, unit_kind_id: 8, description: "No product description provided")