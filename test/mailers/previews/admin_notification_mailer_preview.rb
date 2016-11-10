# Preview all emails at http://localhost:3000/rails/mailers/admin_notification_mailer
class AdminNotificationMailerPreview < ActionMailer::Preview
  include TestLib

  #http://localhost:3000/rails/mailers/admin_notification_mailer/general_message
  def general_message
    AdminNotificationMailer.general_message("my subject", "my body")
  end

  #http://localhost:3000/rails/mailers/admin_notification_mailer/receiving
  def receiving

return AdminNotificationMailer.receiving(nil)

    #create distributor D1    
    if (d1 = User.find_by(email: "d1@d.com"))
      d1.destroy
    end
    d1 = create_distributor("d1 name", "d1@d.com")
    #create business interface
    create_business_interface(d1)
    d1.settings.update(conditional_payment: false)
        
    #create producer P1
    if (p1 = User.find_by(email: "p1@p.com"))
      p1.destroy
    end
    p1 = create_producer("P1", "p1@p.com", d1, order_min = 0)
    #create posting P1P1
    #create posting P1P2

    #create producer P2
    if (p2 = User.find_by(email: "p2@p.com"))
      p2.destroy
    end
    p2 = create_producer("P2", "p2@p.com", d1, order_min = 0)
    #create posting P2P1
    #create posting P2P2

    bob = create_user("bob", "bob@b.com")

    mail = AdminNotificationMailer.receiving(nil)

    bob.destroy
    p1.destroy
    p2.destroy
    d1.destroy

    return mail

  end

end