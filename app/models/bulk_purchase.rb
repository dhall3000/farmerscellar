class BulkPurchase < ActiveRecord::Base
  has_many :bulk_purchase_receivables
  has_many :purchase_receivables, through: :bulk_purchase_receivables

  has_many :bulk_purchase_purchases
  has_many :purchases, through: :bulk_purchase_purchases

  def load_unpaid_receivables
  	#TODO: this will probably be really inefficient as the db grows. maybe want a boolean for when each record is fully paid off
  	prs = PurchaseReceivable.where("amount_paid < amount")
  	if prs &&  prs.any?
  	  for pr in prs
  	  	purchase_receivables << pr
  	  end
  	end
  end

  def go
  	if purchase_receivables && purchase_receivables.any?
  	  for purchase_receivable in purchase_receivable
  	  	purchase(purchase_receivable)
  	  end
  	  save
  	end    
  end

  private
    def purchase(purchase_receivable)
      purchase_amount = purchase_receivable.amount - purchase_receivable.amount_paid
      authorization = nil
      if purchase_receivable.tote_items && purchase_receivable.tote_items.any?
      	authorization = purchase_receivable.tote_items.authorization
      end
      if authorization
        #do the gateway purchase operation
        response = GATEWAY.capture(authorization.amount * 100, authorization.transaction_id)
        gross_amount = response.params["gross_amount"].to_f
        fee_amount = response.params["fee_amount"].to_f
        net_amount = gross_amount - fee_amount

        #create a new purchase object
        purchases.build(
        	response: response,
        	#amount: value[:amount], TODO: i think this column should be removed from the db altogether
        	token: token,
        	payer_id: authorization.payer_id,
        	gross_amount: gross_amount,
        	fee_amount: fee_amount,
        	net_amount: net_amount
        	)

        net_reduction_factor = 1.0 - (net_amount / gross_amount)

        if response.success?
          #for each tote_item:
            #1) change toteitems' states to PURCHASED
            #2) create a new PaymentPayable record
          purchase_receivable.tote_items.each do |tote_item|
            tote_item.update(status: ToteItem.states[:PURCHASED])
            tote_item_purchase_amount = tote_item.quantity * tote_item.price
            net_after_payment_fees = tote_item_purchase_amount * net_reduction_factor
            product_id = tote_item.posting.product_id
            producer_id = tote_item.posting.user_id
            farmers_cellar_commission_factor = tote_item.posting.product.producer_product_commissions.where(product_id: product_id, user_id: producer_id).last
            farmers_cellar_commission = farmers_cellar_commission_factor * net_after_payment_fees
            producer_sales = net_after_payment_fees - @farmers_cellar_commission
            #TODO: record farmers_cellar_commission in FC master sales table
            tote_item.payment_payables.create(amount: producer_sales, amount_paid: 0)
            payment_payable = tote_item.payment_payables.last
            payment_payable.users << User.find(producer_id)
            payment_payable.save
          end                    
          previously_paid = purchase_receivable.amount_paid
          purchase_receivable.update(amount_paid: gross_amount + previously_paid)
        else    
          #TODO: this is the scenario where a purchase dind't work out. we probably need to record this in the db also, probably right here in the purchases table? we'll also need to somehow notify the customer and the admin that payment failed
          #and that their account is now on hold
        end        
      end
    end
end
