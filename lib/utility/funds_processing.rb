require_relative '../../app/helpers/tote_items_helper'
require_relative 'junk_closet'

include ToteItemsHelper
include ActionView::Helpers::NumberHelper

class FundsProcessing  

	def self.do_bulk_customer_purchase

    puts "FundsProcessing.do_bulk_customer_purchase start"
		
		#do bulk purchase
		values = bulk_purchase_new    

		purchase_receivable_ids = []

    if !values.nil? && values[:bulk_purchase] != nil && values[:bulk_purchase].purchase_receivables != nil && values[:bulk_purchase].purchase_receivables.any?
      values[:bulk_purchase].purchase_receivables.each do |pr|
        purchase_receivable_ids << pr.id
      end
    end

    if purchase_receivable_ids.any?
      bulk_purchase = bulk_purchase_create(purchase_receivable_ids)[:bulk_purchase]    
    end		

    if bulk_purchase != nil
      bulk_purchase.do_bulk_email_communication
    end

    puts "FundsProcessing.do_bulk_customer_purchase end"

	end

  #these are all the users who currently have filled tote item (or actually we're about to change it sot hat it doesn't matter
  #the state of the toteitem, but rather they have more than zero unpurchased purchase receivables) that don't have any more
  #deliveries scheduled for later this week. in other words, we should pull funds off these users' accounts
  def self.get_purchase_users

    #get all filled tote items where the users of such have no deliveries scheduled later this week
    num_days_till_end_of_week = ENDOFWEEK - Time.zone.today.wday
    time_range = Time.zone.today.midnight..(Time.zone.today.midnight + num_days_till_end_of_week.days)
    #these are the users that have some filled tote items
    filled_users = User.select(:id).joins(:tote_items).where("tote_items.status = ?", ToteItem.states[:FILLED]).distinct
    #among these users, which also have toteitems in either AUTHORIZED or COMMITTED states?
    delivery_later_this_week_users = User.select(:id).joins(tote_items: :posting).where("tote_items.status" => [ToteItem.states[:AUTHORIZED], ToteItem.states[:COMMITTED]], 'postings.delivery_date' => time_range).distinct
    purchase_users = filled_users.where.not(id: delivery_later_this_week_users)

    return purchase_users

  end

	def self.bulk_purchase_new

    puts "FundsProcessing.bulk_purchase_new start"

		bulk_purchase = BulkPurchase.new(gross: 0, payment_processor_fee_withheld_from_us: 0, commission: 0, net: 0)
  	bulk_purchase.load_unpurchased_receivables_for_users(get_purchase_users)

    if bulk_purchase.purchase_receivables.size < 1
      puts "zero purchase_receivables"
      puts "FundsProcessing.bulk_purchase_new end"
      return
    end

    puts "------"
    s = JunkCloset.puts_helper("", "BulkPurchase id", bulk_purchase.id.to_s)
    s = JunkCloset.puts_helper(s, "gross", number_to_currency(bulk_purchase.gross))
    s = JunkCloset.puts_helper(s, "payment_processor_fee_withheld_from_us", number_to_currency(bulk_purchase.payment_processor_fee_withheld_from_us))
    s = JunkCloset.puts_helper(s, "commission", number_to_currency(bulk_purchase.commission))
    s = JunkCloset.puts_helper(s, "net", number_to_currency(bulk_purchase.net))
    s = JunkCloset.puts_helper(s, "payment_processor_fee_withheld_from_producer", number_to_currency(bulk_purchase.payment_processor_fee_withheld_from_producer))
    s = s + " new'd with the following PurchaseReceivables:"
    puts s     

    bulk_purchase.purchase_receivables.each do |pr|
      puts "PurchaseReceivable id: " + pr.id.to_s + " amount: " + number_to_currency(pr.amount) + " amount_purchased: " + number_to_currency(pr.amount_purchased)
      pr.tote_items.each do |ti|
        ti.update(status: ToteItem.states[:PURCHASEPENDING])
      end
    end    
      
    puts "FundsProcessing.bulk_purchase_new end"

  	return {bulk_purchase: bulk_purchase}
  	
	end

	def self.bulk_purchase_create(purchase_receivable_ids)

    puts "FundsProcessing.bulk_purchase_create start"
    
    if purchase_receivable_ids != nil
    	purchase_receivables = PurchaseReceivable.find(purchase_receivable_ids)
    	if purchase_receivables != nil && purchase_receivables.count > 0
        puts JunkCloset.puts_helper("", "num PurchaseReceivables we're about to loop over", purchase_receivables.count.to_s)
    	  bulk_purchase = BulkPurchase.new(gross: 0, payment_processor_fee_withheld_from_us: 0, commission: 0, net: 0)
    	  for pr in purchase_receivables
    	    bulk_purchase.purchase_receivables << pr
    	  end
        bulk_purchase.go
      end
    end

    puts "FundsProcessing.bulk_purchase_create end"

    return {bulk_purchase: bulk_purchase}

	end

end