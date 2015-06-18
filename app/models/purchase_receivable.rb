class PurchaseReceivable < ActiveRecord::Base
  has_many :bulk_buy_purchase_receivables
  has_many :bulk_buys, through: :bulk_buy_purchase_receivables

  has_many :user_purchase_receivables
  has_many :users, through: :user_purchase_receivables

  has_many :purchase_receivable_tote_items
  has_many :tote_items, through: :purchase_receivable_tote_items

  has_many :bulk_purchase_receivables
  has_many :bulk_purchases, through: :bulk_purchase_receivables

  has_many :purchase_purchase_receivables
  has_many :purchases, through: :purchase_purchase_receivables

  def purchase
    purchase_amount = amount - amount_paid
    authorization = nil
    if tote_items && tote_items.any?
      authorization = tote_items.last.authorization
    end
    if authorization
      #do the gateway purchase operation
      #TODO: you actually shouldn't blindly capture the full authorization.amount. what if some has already been paid on this purchasereceivable? instead,
      #what should be done is compute the amount outstanding and capture only that amount

      if amount > authorization.amount
        #TODO: there is some kind of error that's gone on. we should not proceed until we figure out what to do. perhaps we should raise an alert to the admin
        #to manually process this one and not let the robot do it
      end

      amount_to_capture = amount - amount_paid

      if USEGATEWAY
        response = GATEWAY.capture(amount_to_capture * 100, authorization.transaction_id)
      else
        response = FakeCaptureResponse.new(amount_to_capture * 100, authorization.transaction_id)
      end
        
      gross_amount = response.params["gross_amount"].to_f
      fee_amount = response.params["fee_amount"].to_f
      net_amount = gross_amount - fee_amount

      #create a new purchase object
      purchases.build(
      	response: response,        	
      	transaction_id: response.params["transaction_id"],
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
        tote_items.each do |tote_item|
          tote_item.update(status: ToteItem.states[:PURCHASED])
          tote_item_purchase_amount = tote_item.quantity * tote_item.price
          net_after_payment_fees = tote_item_purchase_amount * net_reduction_factor
          product_id = tote_item.posting.product_id
          producer_id = tote_item.posting.user_id
          #farmers_cellar_commission_factor = tote_item.posting.product.producer_product_commissions.where(product_id: product_id, user_id: producer_id).last
          #farmers_cellar_commission = farmers_cellar_commission_factor * net_after_payment_fees
          #producer_sales = net_after_payment_fees - @farmers_cellar_commission
          #TODO: record farmers_cellar_commission in FC master sales table
          #tote_item.payment_payables.create(amount: producer_sales, amount_paid: 0)
          #payment_payable = tote_item.payment_payables.last
          #payment_payable.users << User.find(producer_id)
          #payment_payable.save
        end                    
        previously_paid = amount_paid
        update(amount_paid: gross_amount + previously_paid)
      else    
        #TODO: this is the scenario where a purchase dind't work out. we probably need to record this in the db also, probably right here in the purchases table? we'll also need to somehow notify the customer and the admin that payment failed
        #and that their account is now on hold
      end        
    else
      #TODO: we should probably raise this for the admin to manually process
      #this block happens if we somehow didn't find an authorization to use
      #debugger
    end
  end
end

class FakeCaptureResponse
  attr_reader :params

  def initialize(amount_in_cents, authorization_transaction_id)

    percentage = 0.035
    fee_amount = amount_in_cents * percentage / 100

    @success = true
    @params = {
      "transaction_id" => authorization_transaction_id,
      "gross_amount" => (amount_in_cents / 100).to_s,
      "fee_amount" => fee_amount.to_s
    }
  end

  def success?
    @success
  end
end