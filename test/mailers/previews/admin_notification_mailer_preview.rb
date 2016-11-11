# Preview all emails at http://localhost:3000/rails/mailers/admin_notification_mailer
class AdminNotificationMailerPreview < ActionMailer::Preview
  include TestLib

  #http://localhost:3000/rails/mailers/admin_notification_mailer/general_message
  def general_message
    AdminNotificationMailer.general_message("my subject", "my body")
  end

  #http://localhost:3000/rails/mailers/admin_notification_mailer/receiving
  def receiving

    db_objects = create_distributor_posting_tree("distributor1", "producer1", "producer2")
    db_objects += create_distributor_posting_tree("distributor2", "producer3", "producer4")
    delivery_date = get_first_delivery_date_from_db_objects(db_objects)

    postings_by_creditor = Posting.postings_by_creditor(delivery_date)

    mail = AdminNotificationMailer.receiving(postings_by_creditor, delivery_date)

    destroy_objects(db_objects)

    return mail

  end

  def get_first_delivery_date_from_db_objects(db_objects)

    db_objects.each do |obj|
      if obj.class.name == "Posting"
        return obj.delivery_date
      end
    end

    return nil

  end

  def create_distributor_posting_tree(distributor = "d1", producer1 = "p1", producer2 = "p2")

    db_objects = []

    #create distributor D1
    db_objects << (d1 = create_distributor(distributor, "#{distributor}@d.com"))
        
    #create producer P1
    db_objects << (p1 = create_producer(producer1, "#{producer1}@p.com", d1, order_min = 0))
    #create posting P1P1
    db_objects << (p1p1 = create_posting(p1, 1.25, get_product("Apples"), get_unit("Pound"), get_delivery_date(100)))
    #create posting P1P2
    db_objects << create_posting(p1, 1.50, get_product("Oranges"), get_unit("Pound"), get_delivery_date(100))

    #create producer P2
    db_objects << (p2 = create_producer(producer2, "#{producer2}@p.com", d1, order_min = 0))
    #create posting P2P1
    db_objects << create_posting(p1, 1.50, get_product("Zuchini"), get_unit("Whole"), get_delivery_date(100))
    #create posting P2P2
    db_objects << create_posting(p1, 1.75, get_product("Carrots"), get_unit("Bunch"), get_delivery_date(100))

    return db_objects

  end

end