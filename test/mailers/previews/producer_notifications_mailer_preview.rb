# Preview all emails at http://localhost:3000/rails/mailers/producer_notifications_mailer
class ProducerNotificationsMailerPreview < ActionMailer::Preview

  #http://localhost:3000/rails/mailers/producer_notifications_mailer/current_orders
  def current_orders
  	postings = Posting.all
    ToteItem.all.update_all(state: ToteItem.states[:COMMITTED])
  	creditor = postings.first.user.get_creditor
    ProducerNotificationsMailer.current_orders(creditor, postings)
  end

  #http://localhost:3000/rails/mailers/producer_notifications_mailer/current_orders_plain
  def current_orders_plain
    #make a fresh posting
    farmer = User.find_by(email: "f1@f.com")
    delivery_date = Time.zone.now.midnight + 2.days
    if delivery_date.sunday?
      delivery_date = delivery_date + 1.day
    end

    ProducerProductUnitCommission.create(user: farmer, product: Product.first, unit: Unit.first, commission: 0.05)
    posting = Posting.new(unit: Unit.first, product: Product.first, user: farmer, description: "descrip", quantity_available: 100, price: 1.25, live: true, commitment_zone_start: Time.zone.now - 1.second, delivery_date: delivery_date)
    posting.save
    #make some tote items for that posting
    user = User.find_by(email: "c1@c.com")    
    ti1 = ToteItem.new(quantity: 2, posting: posting, user: user, price: posting.price, state: ToteItem.states[:COMMITTED])
    ti1.save
    ti2 = ToteItem.new(quantity: 3, posting: posting, user: user, price: posting.price, state: ToteItem.states[:COMMITTED])
    ti2.save

    creditor = posting.user.get_creditor
    ProducerNotificationsMailer.current_orders(creditor, [posting])
  end

  #http://localhost:3000/rails/mailers/producer_notifications_mailer/current_orders_product_id_code
  #this should show the basic order email with the addition of the product id column. one of the rows should have a product identifier code 
  #and the other should be blank
  def current_orders_product_id_code
    #make a fresh posting
    farmer = User.find_by(email: "f1@f.com")
    delivery_date = Time.zone.now.midnight + 2.days
    if delivery_date.sunday?
      delivery_date = delivery_date + 1.day
    end

    ProducerProductUnitCommission.create(user: farmer, product: Product.first, unit: Unit.first, commission: 0.05)
    posting1 = Posting.new(unit: Unit.first, product: Product.first, user: farmer, description: "descrip", quantity_available: 100, price: 1.25, live: true, commitment_zone_start: Time.zone.now - 1.second, delivery_date: delivery_date, product_id_code: "awesomxyz")
    posting1.save
    #make some tote items for that posting
    user = User.find_by(email: "c1@c.com")    
    ti1 = ToteItem.new(quantity: 2, posting: posting1, user: user, price: posting1.price, state: ToteItem.states[:COMMITTED])
    ti1.save
    ti2 = ToteItem.new(quantity: 3, posting: posting1, user: user, price: posting1.price, state: ToteItem.states[:COMMITTED])
    ti2.save


    posting2 = Posting.new(unit: Unit.first, product: Product.first, user: farmer, description: "descrip", quantity_available: 100, price: 1.25, live: true, commitment_zone_start: Time.zone.now - 1.second, delivery_date: delivery_date)
    posting2.save
    #make some tote items for that posting
    user = User.find_by(email: "c1@c.com")    
    ti1 = ToteItem.new(quantity: 2, posting: posting2, user: user, price: posting2.price, state: ToteItem.states[:COMMITTED])
    ti1.save
    ti2 = ToteItem.new(quantity: 3, posting: posting2, user: user, price: posting2.price, state: ToteItem.states[:COMMITTED])
    ti2.save

    creditor = posting1.user.get_creditor
    ProducerNotificationsMailer.current_orders(creditor, [posting1, posting2])

  end

  #http://localhost:3000/rails/mailers/producer_notifications_mailer/current_orders_fancy
  #this should show the basic order email with the addition of the product id column. one of the rows should have a product identifier code 
  #and the other should be blank. it should also have one row that has cases.
  def current_orders_fancy
    #make a fresh posting
    farmer = User.find_by(email: "f1@f.com")
    delivery_date = Time.zone.now.midnight + 2.days
    if delivery_date.sunday?
      delivery_date = delivery_date + 1.day
    end

    ProducerProductUnitCommission.create(user: farmer, product: Product.first, unit: Unit.first, commission: 0.05)
    posting1 = Posting.new(unit: Unit.first, product: Product.first, user: farmer, description: "descrip", quantity_available: 100, price: 1.25, live: true, commitment_zone_start: Time.zone.now - 1.second, delivery_date: delivery_date, product_id_code: "awesomxyz")
    posting1.save
    #make some tote items for that posting
    user = User.find_by(email: "c1@c.com")    
    ti1 = ToteItem.new(quantity: 2, posting: posting1, user: user, price: posting1.price, state: ToteItem.states[:COMMITTED])
    ti1.save
    ti2 = ToteItem.new(quantity: 3, posting: posting1, user: user, price: posting1.price, state: ToteItem.states[:COMMITTED])
    ti2.save


    posting2 = Posting.new(unit: Unit.first, product: Product.first, user: farmer, description: "descrip", quantity_available: 100, price: 1.25, live: true, commitment_zone_start: Time.zone.now - 1.second, delivery_date: delivery_date)
    posting2.save
    #make some tote items for that posting
    user = User.find_by(email: "c1@c.com")    
    ti1 = ToteItem.new(quantity: 2, posting: posting2, user: user, price: posting2.price, state: ToteItem.states[:COMMITTED])
    ti1.save
    ti2 = ToteItem.new(quantity: 3, posting: posting2, user: user, price: posting2.price, state: ToteItem.states[:COMMITTED])
    ti2.save

    posting3 = Posting.new(unit: Unit.first, product: Product.first, user: farmer, description: "descrip", quantity_available: 100, price: 1.25, live: true, commitment_zone_start: Time.zone.now - 1.second, delivery_date: delivery_date, units_per_case: 2)
    posting3.save
    #make some tote items for that posting
    user = User.find_by(email: "c1@c.com")    
    ti1 = ToteItem.new(quantity: 2, posting: posting3, user: user, price: posting3.price, state: ToteItem.states[:COMMITTED])
    ti1.save
    ti2 = ToteItem.new(quantity: 3, posting: posting3, user: user, price: posting3.price, state: ToteItem.states[:COMMITTED])
    ti2.save

    creditor = posting1.user.get_creditor
    ProducerNotificationsMailer.current_orders(creditor, [posting1, posting2, posting3])

  end

end