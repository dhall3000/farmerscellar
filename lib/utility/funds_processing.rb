require_relative '../../app/helpers/tote_items_helper'
require_relative 'junk_closet'

include ToteItemsHelper
include ActionView::Helpers::NumberHelper

class FundsProcessing  

	def self.do_bulk_customer_purchase
    puts "FundsProcessing.do_bulk_customer_purchase start"
		values = bulk_buy_new			
		admin = User.where(account_type: User.types[:ADMIN]).first
		bulk_buy_create(values[:filled_tote_items], admin)
		#do bulk purchase
		values = bulk_purchase_new    

		purchase_receivables = []

    if values[:bulk_purchase] != nil && values[:bulk_purchase].purchase_receivables != nil && values[:bulk_purchase].purchase_receivables.any?
      values[:bulk_purchase].purchase_receivables.each do |pr|
        purchase_receivables << pr
      end
    end

    if purchase_receivables.any?
      bulk_purchase = bulk_purchase_create(purchase_receivables)[:bulk_purchase]    
    end		

    if bulk_purchase != nil
      send_purchase_receipts(bulk_purchase)    
    end

    puts "FundsProcessing.do_bulk_customer_purchase end"

	end

	def self.bulk_buy_new

    puts "FundsProcessing.bulk_buy_new start"

		ret = {}

  	ret[:filled_tote_items] = ToteItem.where(status: ToteItem.states[:FILLED])  	

    user_ids = ret[:filled_tote_items].select(:user_id).distinct    
    ret[:user_infos] = []
    ret[:total_bulk_buy_amount] = 0

    for user_id in user_ids
      user_info = {email: '', id: 0, total_amount: 0 }
      tote_items_by_user = ret[:filled_tote_items].where(user_id: user_id.user_id)
      for tote_item_by_user in tote_items_by_user
        user_info[:total_amount] = (user_info[:total_amount] + get_gross_item(tote_item_by_user).round(2))
        user_info[:email] = tote_item_by_user.user.email
        user_info[:id] = tote_item_by_user.user.id
      end
      ret[:total_bulk_buy_amount] = (ret[:total_bulk_buy_amount] + user_info[:total_amount]).round(2)
      ret[:user_infos] << user_info
    end

    puts "------"
    ret[:user_infos].each do |user_info|
      puts "Purchase info for user: " + user_info[:email]
      ret[:filled_tote_items].where(user_id: user_info[:id]).each do |tote_item|
        puts "ToteItem id: " + tote_item.id.to_s + ", amount: " + number_to_currency(get_gross_item(tote_item))
      end
      puts "Total amount for user: " + number_to_currency(user_info[:total_amount])
      puts "------"
    end

    puts "Total BulkBuy amount: " + number_to_currency(ret[:total_bulk_buy_amount])
    puts "FundsProcessing.bulk_buy_new end"

    return ret

	end

	def self.bulk_buy_create(filled_tote_item_ids, admin)

    puts "FundsProcessing.bulk_buy_create start"

    #create a bulkbuy object
    bulk_buy = BulkBuy.new
    bulk_buy.admins << admin
    bulk_buy.amount = 0

    authorizations = {}

    #get the filled tote items and group them by user's authorization
  	filled_tote_items = ToteItem.where(id: filled_tote_item_ids)
    
    if filled_tote_items == nil || filled_tote_items.count < 1
      return
    end

  	for filled_tote_item in filled_tote_items
      bulk_buy.tote_items << filled_tote_item
  	  if filled_tote_item.checkouts != nil && filled_tote_item.checkouts.any?
  	  	if filled_tote_item.checkouts.last.authorizations != nil && filled_tote_item.checkouts.last.authorizations.any?
  	  	  authorization = filled_tote_item.checkouts.last.authorizations.last
  	  	  if authorizations[authorization.token] == nil
  	  	  	authorizations[authorization.token] = {amount: 0, authorization: authorization, filled_tote_items: []}
  	  	  end
  	  	  authorizations[authorization.token][:amount] = (authorizations[authorization.token][:amount] + (filled_tote_item.quantity * filled_tote_item.price).round(2)).round(2)
  	  	  authorizations[authorization.token][:filled_tote_items] << filled_tote_item
  	  	end
  	  end
  	end

    #authorizations[token][:amount] //this is the purchase_receivable amount
    #authorizations[token][:authorization]
    #authorizations[token][:filled_tote_items]

    authorizations.each do |token, value|
      ftis = value[:filled_tote_items]
      if ftis == nil || !ftis.any?
        next
      end

      bulk_buy.purchase_receivables.build(amount: value[:amount], amount_purchased: 0, kind: PurchaseReceivable.kind[:NORMAL])
      pr = bulk_buy.purchase_receivables.last
      user = User.find(ftis.first.user_id)                      
      pr.users << user

      ftis.each do |fti|
        pr.tote_items << fti
        fti.update(status: ToteItem.states[:PURCHASEPENDING])
      end                              

      #this represents the total value of everything that was filled for this bulk buy
      bulk_buy.amount = (bulk_buy.amount + value[:amount]).round(2)
    end
  	#save the bulkbuy object
  	bulk_buy.save

    puts "------"
    puts "BulkBuy id: " + bulk_buy.id.to_s + " amount: " + number_to_currency(bulk_buy.amount) + " created with the following PurchaseReceivables:"

    bulk_buy.purchase_receivables.each do |pr|
      puts "PurchaseReceivable id: " + pr.id.to_s + " amount: " + number_to_currency(pr.amount) + " amount_purchased: " + number_to_currency(pr.amount_purchased)
    end

    puts "FundsProcessing.bulk_buy_create end"    

  	return {bulk_buy: bulk_buy}

	end

	def self.bulk_purchase_new

    puts "FundsProcessing.bulk_purchase_new start"

		bulk_purchase = BulkPurchase.new(gross: 0, payment_processor_fee_withheld_from_us: 0, commission: 0, net: 0)
  	bulk_purchase.load_unpurchased_receivables

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
    end    

    puts "FundsProcessing.bulk_purchase_new end"

  	return {bulk_purchase: bulk_purchase}
  	
	end

	def self.bulk_purchase_create(purchase_receivables)

    puts "FundsProcessing.bulk_purchase_create start"
    
    if purchase_receivables != nil
    	purchase_receivables = PurchaseReceivable.find(purchase_receivables)
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

  private
    def self.send_purchase_receipts(bulk_purchase)

      if bulk_purchase.nil?
        return
      end

      tote_items_by_user = get_tote_items_by_user(bulk_purchase)

      tote_items_by_user.each do |user, tote_items|
        UserMailer.purchase_receipt(user, tote_items).deliver_now
      end

    end

    def self.get_tote_items_by_user(bulk_purchase)
      tote_items_by_user = {}

      bulk_purchase.purchase_receivables.each do |pr|
        pr.tote_items.each do |tote_item|
          if !tote_items_by_user.has_key?(tote_item.user)
            tote_items_by_user[tote_item.user] = []
          end
          tote_items_by_user[tote_item.user] << tote_item
        end
      end

      return tote_items_by_user
    end

end