require 'test_helper'
require 'utility/rake_helper'
require 'bulk_buy_helper'

class DistributorTest < BulkBuyer
  
  def setup
    super  
  end

  #i want one customer to purchase three different items, each from different producers. two of the producers have the same
  #distributor. the 3rd producer does not have a distributor.

  test "distributor and producer should get order emails" do
    
    customer = users(:c18)
    #do one time checkout and authorization
    create_authorization_for_customer(customer)
    #travel to commitment zone start time    
    travel_to customer.tote_items.first.posting.commitment_zone_start
    #this should move postings from OPEN to COMMITMENTZONE
    clear_mailer
    RakeHelper.do_hourly_tasks    
    assert_equal 3, ActionMailer::Base.deliveries.count
    
    assert_appropriate_email_exists("d1order_email@d.com", "Current orders for upcoming deliveries", "Hi Bigtime Distributor Business Interface,")
    assert_appropriate_email_exists("d1order_email@d.com", "Current orders for upcoming deliveries", "Below are orders for your upcoming delivery.")
    assert_appropriate_email_exists("d1order_email@d.com", "Current orders for upcoming deliveries", "F6 FARM")
    assert_appropriate_email_exists("d1order_email@d.com", "Current orders for upcoming deliveries", "F7 FARM")

    assert_appropriate_email_exists("f8order_email@f.com", "Current orders for upcoming deliveries", "Hi F8 FARM Business Interface,")
    assert_appropriate_email_exists("f8order_email@f.com", "Current orders for upcoming deliveries", "Below are orders for your upcoming delivery.")

    
    assert_appropriate_email_exists("david@farmerscellar.com", "commit_totes job summary report", "number of tote_items transitioned from AUTHORIZED -> COMMITTED: 3.")

    #assert that neither the distributor nor producer got emailed
    customer.tote_items.each do |tote_item|
      assert_not_email_to(tote_item.posting.user.get_creditor.email)
    end

    travel_back
    clear_mailer

  end

  test "distributor and producer should not get order emails" do

    #first modify the business interfaces properly
    bi = business_interfaces(:one)
    bi.update(order_email_accepted: false, order_email: nil, order_instructions: "go to www.bigtimedistributor.com and manually submit order there. be sure to use a 1 when placing order.")
    bi.reload
    assert_not bi.order_email_accepted
    assert_equal nil, bi.order_email
    assert_not bi.order_instructions.nil?

    bi = business_interfaces(:two)
    bi.update(order_email_accepted: false, order_email: nil, order_instructions: "go to www.f8farm.com and manually submit order there. do this before noon!")
    bi.reload
    assert_not bi.order_email_accepted
    assert_equal nil, bi.order_email
    assert_not bi.order_instructions.nil?

    customer = users(:c18)
    #do one time checkout and authorization
    create_authorization_for_customer(customer)
    #travel to commitment zone start time
    posting = customer.tote_items.first.posting
    travel_to posting.commitment_zone_start
    #this should move postings from OPEN to COMMITMENTZONE
    clear_mailer
    RakeHelper.do_hourly_tasks    
    assert_equal 3, ActionMailer::Base.deliveries.count

    assert_appropriate_email_exists("david@farmerscellar.com", "admin action required: Current orders for upcoming deliveries", "Hi david@farmerscellar.com,")
    assert_appropriate_email_exists("david@farmerscellar.com", "admin action required: Current orders for upcoming deliveries", "Below are orders for your upcoming delivery.")    
    assert_appropriate_email_exists("david@farmerscellar.com", "admin action required: Current orders for upcoming deliveries", "F6 FARM")
    assert_appropriate_email_exists("david@farmerscellar.com", "admin action required: Current orders for upcoming deliveries", "F7 FARM")
    assert_appropriate_email_exists("david@farmerscellar.com", "admin action required: Current orders for upcoming deliveries", "Order Instructions: go to www.bigtimedistributor.com and manually submit order there. be sure to use a 1 when placing order.")

    assert_appropriate_email_exists("david@farmerscellar.com", "admin action required: Current orders for upcoming deliveries", "Hi david@farmerscellar.com,")
    assert_appropriate_email_exists("david@farmerscellar.com", "admin action required: Current orders for upcoming deliveries", "Below are orders for your upcoming delivery.")    
    assert_appropriate_email_exists("david@farmerscellar.com", "admin action required: Current orders for upcoming deliveries", "Order Instructions: go to www.f8farm.com and manually submit order there. do this before noon!")

    assert_appropriate_email_exists("david@farmerscellar.com", "commit_totes job summary report", "number of tote_items transitioned from AUTHORIZED -> COMMITTED: 3.")

    #assert that neither the distributor nor producer got emailed
    customer.tote_items.each do |tote_item|
      assert_not_email_to(tote_item.posting.user.get_creditor.email)
    end

    travel_back
    clear_mailer

  end

  test "distributor and producer should get order emails and payments" do

    customer = users(:c18)
    #do one time checkout and authorization
    create_authorization_for_customer(customer)
    #travel to commitment zone start time
    posting = customer.tote_items.first.posting
    travel_to posting.commitment_zone_start
    #this should move postings from OPEN to COMMITMENTZONE
    clear_mailer
    RakeHelper.do_hourly_tasks    
    assert_equal 3, ActionMailer::Base.deliveries.count
    
    assert_appropriate_email_exists("d1order_email@d.com", "Current orders for upcoming deliveries", "Hi Bigtime Distributor Business Interface,")
    assert_appropriate_email_exists("d1order_email@d.com", "Current orders for upcoming deliveries", "Below are orders for your upcoming delivery.")    
    assert_appropriate_email_exists("d1order_email@d.com", "Current orders for upcoming deliveries", "F6 FARM")
    assert_appropriate_email_exists("d1order_email@d.com", "Current orders for upcoming deliveries", "F7 FARM")

    assert_appropriate_email_exists("f8order_email@f.com", "Current orders for upcoming deliveries", "Hi F8 FARM Business Interface,")
    assert_appropriate_email_exists("f8order_email@f.com", "Current orders for upcoming deliveries", "Below are orders for your upcoming delivery.")    
    
    assert_appropriate_email_exists("david@farmerscellar.com", "commit_totes job summary report", "number of tote_items transitioned from AUTHORIZED -> COMMITTED: 3.")    
    clear_mailer

    #now travel to one second past midnight on delivery day
    travel_to posting.delivery_date + 1
    #now do some fills
    assert_equal 0, PurchaseReceivable.count
    customer.tote_items.each do |tote_item|
      simulate_order_filling_for_postings([tote_item.posting], fill_all_tote_items = true)
    end    
    #now travel to funds processing time
    travel_to posting.delivery_date + 22.hours
    #now process funds
    clear_mailer
    assert_equal 0, PaymentPayable.count
    RakeHelper.do_hourly_tasks

    #there are 3 tote items and there should be 1 pp for every ti
    assert_equal 3, PaymentPayable.count
    #there were 3 postings belonging to 3 different producers. but 2 of the producers have a common distributor. the 3rd posting
    #belogns to producer who is his own creditor. so there should be two payments.
    assert_equal 2, Payment.count

    #pr fully purchased
    #should be one pr for each tote item
    assert_equal 3, PurchaseReceivable.count
    pr_sum = 0
    PurchaseReceivable.all.each do |pr|
      assert_equal "c18@c.com", pr.users.first.email
      assert_equal pr.amount_purchased, pr.amount
      assert_equal PurchaseReceivable.kind[:NORMAL], pr.kind
      assert_equal PurchaseReceivable.states[:COMPLETE], pr.state
      pr_sum += pr.amount_purchased
    end
    #purchase receivable amount > 0
    assert pr_sum > 0
    #sum of pp's > 0
    pp_sum = 0
    payment_emails = {}
    PaymentPayable.all.each do |pp|
      assert pp.amount > 0
      assert_equal pp.amount_paid, pp.amount

      payment_email = pp.users.first.get_business_interface.paypal_email
      
      if !payment_emails.has_key?(payment_email)
        payment_emails[payment_email] = 0
      end
      payment_emails[payment_email] = (payment_emails[payment_email] + pp.amount).round(2)
      pp_sum = (pp_sum + pp.amount).round(2)
    end
    assert pp_sum > 0
    #sum of pp's equals amount reported in payment invoice
    payment_emails.each do |payment_email, amount|
      assert_appropriate_email_exists(payment_email, "Payment receipt", amount.to_s)
    end

    #verify funds sent via paypal
    #NOTE: there's not a great way to do this as we don't store a record of all who were paid via masspay. best proxy for now is all the email checking
    #below. if a payment receipt was emailed to the creditor that means they were paid via paypal. if the payment receipt was mailed to me that means
    #the creditor was not paid via paypal.
    #verify funds sent to the right address
    #this also is handled indirectly through all the email checking below.

    #there should be purchase receipt to customer, payment invoice to f8 and d1, bulk purchase report to admin, bulk payment report to admin
    assert_equal 5, ActionMailer::Base.deliveries.count
    #purchase receipt (to customer)
    assert_appropriate_email_exists("c18@c.com", "Purchase receipt", "Hello c18")
    assert_appropriate_email_exists("c18@c.com", "Purchase receipt", "Here is your Farmer's Cellar purchase receipt")    
    #bulk purchase report (to admin)    
    assert_appropriate_email_exists("david@farmerscellar.com", "bulk purchase report", ". ")
    #payment receipt (to f8 creditor)
    assert_appropriate_email_exists("f8paypal_email@f.com", "Payment receipt", "Hi F8 FARM Business Interface,")
    assert_appropriate_email_exists("f8paypal_email@f.com", "Payment receipt", "We just sent you a total of")
    #payment receipt (to d1 creditor)
    assert_appropriate_email_exists("d1paypal_email@d.com", "Payment receipt", "Hi Bigtime Distributor Business Interface,")
    assert_appropriate_email_exists("d1paypal_email@d.com", "Payment receipt", "We just sent you a total of")
    assert_appropriate_email_exists("d1paypal_email@d.com", "Payment receipt", "F6 FARM")
    assert_appropriate_email_exists("d1paypal_email@d.com", "Payment receipt", "F7 FARM")
    #bulk payment report (to admin)
    assert_appropriate_email_exists("david@farmerscellar.com", "BulkPayment report", "The sum of paypal payments is $#{pp_sum.to_s}") 
    
    travel_back
    clear_mailer

  end

  test "distributor and producer should get order emails but not payments" do 

    #first modify the business interfaces properly
    bi = business_interfaces(:one)
    bi.update(paypal_accepted: false, paypal_email: nil, payment_instructions: "COD")
    bi.reload
    assert_not bi.paypal_accepted
    assert_equal nil, bi.paypal_email    
    assert_not bi.payment_instructions.nil?

    bi = business_interfaces(:two)
    bi.update(paypal_accepted: false, paypal_email: nil, payment_instructions: "Credit card on pickup")
    bi.reload
    assert_not bi.paypal_accepted
    assert_equal nil, bi.paypal_email    
    assert_not bi.payment_instructions.nil?

    customer = users(:c18)
    #do one time checkout and authorization
    create_authorization_for_customer(customer)
    #travel to commitment zone start time
    posting = customer.tote_items.first.posting
    travel_to posting.commitment_zone_start
    #this should move postings from OPEN to COMMITMENTZONE
    clear_mailer
    RakeHelper.do_hourly_tasks    
    assert_equal 3, ActionMailer::Base.deliveries.count
    
    assert_appropriate_email_exists("d1order_email@d.com", "Current orders for upcoming deliveries", "Hi Bigtime Distributor Business Interface,")
    assert_appropriate_email_exists("d1order_email@d.com", "Current orders for upcoming deliveries", "Below are orders for your upcoming delivery.")    
    assert_appropriate_email_exists("d1order_email@d.com", "Current orders for upcoming deliveries", "F6 FARM")
    assert_appropriate_email_exists("d1order_email@d.com", "Current orders for upcoming deliveries", "F7 FARM")

    assert_appropriate_email_exists("f8order_email@f.com", "Current orders for upcoming deliveries", "Hi F8 FARM Business Interface,")
    assert_appropriate_email_exists("f8order_email@f.com", "Current orders for upcoming deliveries", "Below are orders for your upcoming delivery.")    
    
    assert_appropriate_email_exists("david@farmerscellar.com", "commit_totes job summary report", "number of tote_items transitioned from AUTHORIZED -> COMMITTED: 3.")    
    clear_mailer

    #now travel to one second past midnight on delivery day
    travel_to posting.delivery_date + 1
    #now do some fills
    assert_equal 0, PurchaseReceivable.count
    customer.tote_items.each do |tote_item|
      simulate_order_filling_for_postings([tote_item.posting], fill_all_tote_items = true)
    end    
    #now travel to funds processing time
    travel_to posting.delivery_date + 22.hours
    #now process funds
    clear_mailer
    assert_equal 0, PaymentPayable.count
    RakeHelper.do_hourly_tasks

    #there are 3 tote items and there should be 1 pp for every ti
    assert_equal 3, PaymentPayable.count
    #there were 3 postings belonging to 3 different producers. but 2 of the producers have a common distributor. the 3rd posting
    #belogns to producer who is his own creditor. so there should be two payments.
    assert_equal 2, Payment.count

    #pr fully purchased
    #should be one pr for each tote item
    assert_equal 3, PurchaseReceivable.count
    pr_sum = 0
    PurchaseReceivable.all.each do |pr|
      assert_equal "c18@c.com", pr.users.first.email
      assert_equal pr.amount_purchased, pr.amount
      assert_equal PurchaseReceivable.kind[:NORMAL], pr.kind
      assert_equal PurchaseReceivable.states[:COMPLETE], pr.state
      pr_sum += pr.amount_purchased
    end
    #purchase receivable amount > 0
    assert pr_sum > 0
    #sum of pp's > 0
    pp_sum = 0
    payments = {}
    PaymentPayable.all.each do |pp|
      assert pp.amount > 0
      assert_equal pp.amount_paid, pp.amount

      payment = pp.users.first.get_business_interface.name
      
      if !payments.has_key?(payment)
        payments[payment] = {amount: 0, payment: nil}
      end
      payments[payment][:amount] = (payments[payment][:amount] + pp.amount).round(2)
      payments[payment][:payment] = pp.payments.last
      pp_sum = (pp_sum + pp.amount).round(2)
    end
    assert pp_sum > 0

    #sum of pp's equals amount reported in payment invoice
    payments.each do |payment, value|
      assert_appropriate_email_exists("david@farmerscellar.com", "admin action required: Payment receipt", value[:amount].to_s)
    end

    #verify funds sent via paypal
    #NOTE: there's not a great way to do this as we don't store a record of all who were paid via masspay. best proxy for now is all the email checking
    #below. if a payment receipt was emailed to the creditor that means they were paid via paypal. if the payment receipt was mailed to me that means
    #the creditor was not paid via paypal.
    #verify funds sent to the right address
    #this also is handled indirectly through all the email checking below.

    #there should be purchase receipt to customer, payment invoice to f8 and d1, bulk purchase report to admin, bulk payment report to admin
    assert_equal 5, ActionMailer::Base.deliveries.count
    #purchase receipt (to customer)
    assert_appropriate_email_exists("c18@c.com", "Purchase receipt", "Hello c18")
    assert_appropriate_email_exists("c18@c.com", "Purchase receipt", "Here is your Farmer's Cellar purchase receipt")    
    #bulk purchase report (to admin)    
    assert_appropriate_email_exists("david@farmerscellar.com", "bulk purchase report", ". ")

    #payment receipt (to f8 creditor)
    assert_appropriate_email_exists("david@farmerscellar.com", "admin action required: Payment receipt", "Hi david@farmerscellar.com,")
    assert_appropriate_email_exists("david@farmerscellar.com", "admin action required: Payment receipt", "Get payment of $#{payments["Bigtime Distributor Business Interface"][:amount]} to Bigtime Distributor Business Interface for the following products / quantities:")
    assert_appropriate_email_exists("david@farmerscellar.com", "admin action required: Payment receipt", "F6 FARM")
    assert_appropriate_email_exists("david@farmerscellar.com", "admin action required: Payment receipt", "F7 FARM")
    assert_appropriate_email_exists("david@farmerscellar.com", "admin action required: Payment receipt", "Payment ID# #{payments["Bigtime Distributor Business Interface"][:payment].id.to_s}")
    assert_appropriate_email_exists("david@farmerscellar.com", "admin action required: Payment receipt", "Payment Instructions: COD")

    #payment receipt (to d1 creditor)
    assert_appropriate_email_exists("david@farmerscellar.com", "admin action required: Payment receipt", "Get payment of $#{payments["F8 FARM Business Interface"][:amount]} to F8 FARM Business Interface for the following products / quantities:")
    assert_appropriate_email_exists("david@farmerscellar.com", "admin action required: Payment receipt", "Payment ID# #{payments["F8 FARM Business Interface"][:payment].id.to_s}")
    assert_appropriate_email_exists("david@farmerscellar.com", "admin action required: Payment receipt", "Payment Instructions: Credit card on pickup")    

    #bulk payment report (to admin)
    assert_appropriate_email_exists("david@farmerscellar.com", "BulkPayment report", "Here is your message from AdminNotificationMailer")
    assert_appropriate_email_exists("david@farmerscellar.com", "BulkPayment report", "MANUAL PAYMENTS")
    assert_appropriate_email_exists("david@farmerscellar.com", "BulkPayment report", "$#{payments["F8 FARM Business Interface"][:amount]} to F8 FARM Business Interface")
    assert_appropriate_email_exists("david@farmerscellar.com", "BulkPayment report", "$#{payments["Bigtime Distributor Business Interface"][:amount]} to Bigtime Distributor Business Interface")
    assert_appropriate_email_exists("david@farmerscellar.com", "BulkPayment report", "The sum of manual payments is $#{pp_sum.to_s}.")

    bulk_payment_report = get_mail_by_subject("BulkPayment report")    
    assert_not bulk_payment_report.nil?
    
    travel_back
    clear_mailer

  end

  def clear_mailer
    ActionMailer::Base.deliveries.clear
    assert_equal 0, ActionMailer::Base.deliveries.count
  end

end